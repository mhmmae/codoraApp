#!/usr/bin/env python3
import os
import sys
import json
import uuid
from datetime import datetime, timedelta
from pathlib import Path
import hashlib
import logging

# إعداد التسجيل
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class ConversationManager:
    def __init__(self):
        self.config_dir = Path.home() / '.gemini-enhanced'
        self.conversations_dir = self.config_dir / 'conversations'
        self.conversations_index = self.config_dir / 'conversations_index.json'

        # إنشاء المجلدات
        try:
            self.config_dir.mkdir(exist_ok=True)
            self.conversations_dir.mkdir(exist_ok=True)
        except OSError as e:
            logging.error(f"Failed to create configuration directories: {e}")
            # قد تحتاج إلى رفع استثناء أو التعامل مع هذا بشكل أكثر فاعلية
            sys.exit(1) # الخروج إذا لم نتمكن من إنشاء المجلدات الأساسية

        self.index = self.load_index()

    def load_index(self):
        """تحميل فهرس المحادثات"""
        if self.conversations_index.exists():
            try:
                with open(self.conversations_index, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except json.JSONDecodeError as e:
                logging.error(f"Error decoding conversations index JSON: {e}")
                # قد يكون الملف تالفاً، نبدأ بفهرس فارغ
                return {}
            except IOError as e:
                logging.error(f"Error reading conversations index file: {e}")
                return {}
        return {}

    def save_index(self):
        """حفظ فهرس المحادثات"""
        try:
            with open(self.conversations_index, 'w', encoding='utf-8') as f:
                json.dump(self.index, f, ensure_ascii=False, indent=2)
        except IOError as e:
            logging.error(f"Error writing conversations index file: {e}")

    def create_conversation(self, title="محادثة جديدة"):
        """إنشاء محادثة جديدة"""
        conversation_id = str(uuid.uuid4())[:8]
        timestamp = datetime.now().isoformat()

        conversation_data = {
            'id': conversation_id,
            'title': title,
            'created_at': timestamp,
            'last_updated': timestamp,
            'messages': [],
            'tags': [],
            'summary': ''
        }

        # حفظ المحادثة
        conv_file = self.conversations_dir / f"{conversation_id}.json"
        try:
            with open(conv_file, 'w', encoding='utf-8') as f:
                json.dump(conversation_data, f, ensure_ascii=False, indent=2)
        except IOError as e:
            logging.error(f"Error writing new conversation file {conv_file}: {e}")
            return None # فشل في إنشاء المحادثة

        # تحديث الفهرس
        self.index[conversation_id] = {
            'title': title,
            'created_at': timestamp,
            'last_updated': timestamp,
            'message_count': 0,
            'tags': []
        }
        self.save_index()

        return conversation_id

    def add_message(self, conversation_id, prompt, response, context_info=None):
        """إضافة رسالة لمحادثة موجودة"""
        conv_file = self.conversations_dir / f"{conversation_id}.json"

        if not conv_file.exists():
            logging.warning(f"Attempted to add message to non-existent conversation: {conversation_id}")
            return False

        # تحميل المحادثة
        try:
            with open(conv_file, 'r', encoding='utf-8') as f:
                conversation = json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            logging.error(f"Error loading conversation {conversation_id} for adding message: {e}")
            return False

        # إضافة الرسالة الجديدة
        message = {
            'timestamp': datetime.now().isoformat(),
            'prompt': prompt,
            'response': response,
            'context_info': context_info or {}
        }

        conversation['messages'].append(message)
        conversation['last_updated'] = datetime.now().isoformat()

        # حفظ المحادثة المحدثة
        try:
            with open(conv_file, 'w', encoding='utf-8') as f:
                json.dump(conversation, f, ensure_ascii=False, indent=2)
        except IOError as e:
            logging.error(f"Error saving conversation {conversation_id} after adding message: {e}")
            return False

        # تحديث الفهرس
        if conversation_id in self.index:
            self.index[conversation_id]['last_updated'] = conversation['last_updated']
            self.index[conversation_id]['message_count'] = len(conversation['messages'])
            self.save_index()
        else:
            logging.warning(f"Conversation {conversation_id} not found in index during message add.")
            # قد تحتاج إلى إعادة بناء الفهرس هنا أو التعامل مع هذا كخطأ فادح

        return True

    def get_conversation(self, conversation_id):
        """استرجاع محادثة محددة"""
        conv_file = self.conversations_dir / f"{conversation_id}.json"

        if not conv_file.exists():
            return None

        try:
            with open(conv_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            logging.error(f"Error loading conversation {conversation_id}: {e}")
            return None

    def list_conversations(self, limit=20, search_term=None):
        """عرض قائمة المحادثات"""
        conversations = []

        # تحسين: إذا كان هناك search_term، لا تقم بتحميل كل المحادثات إلا إذا كان ذلك ضرورياً
        # حالياً، لا يزال هذا الجزء غير فعال للمحادثات الكبيرة
        for conv_id, conv_info in self.index.items():
            if search_term:
                # البحث في العنوان أولاً لتجنب تحميل الملف إذا لم يكن العنوان مطابقاً
                if search_term.lower() not in conv_info['title'].lower():
                    # إذا لم يطابق العنوان، قم بتحميل المحادثة للبحث في الرسائل
                    conv_data = self.get_conversation(conv_id)
                    if conv_data:
                        search_text = f"{conv_info['title']} "
                        for msg in conv_data['messages']:
                            search_text += f" {msg['prompt']} {msg['response']}"

                        if search_term.lower() not in search_text.lower():
                            continue
                    else:
                        continue # تخطي المحادثات التي لا يمكن تحميلها

            conversations.append({
                'id': conv_id,
                **conv_info
            })

        # ترتيب حسب آخر تحديث
        conversations.sort(key=lambda x: x['last_updated'], reverse=True)

        return conversations[:limit]

    def delete_conversation(self, conversation_id):
        """حذف محادثة"""
        conv_file = self.conversations_dir / f"{conversation_id}.json"

        if conv_file.exists():
            try:
                conv_file.unlink()
            except OSError as e:
                logging.error(f"Error deleting conversation file {conv_file}: {e}")
                return False

        if conversation_id in self.index:
            del self.index[conversation_id]
            self.save_index()
            return True

        logging.warning(f"Attempted to delete non-existent conversation from index: {conversation_id}")
        return False

    def update_conversation_title(self, conversation_id, new_title):
        """تحديث عنوان المحادثة"""
        conv_data = self.get_conversation(conversation_id)
        if not conv_data:
            return False

        conv_data['title'] = new_title
        conv_data['last_updated'] = datetime.now().isoformat()

        # حفظ المحادثة
        conv_file = self.conversations_dir / f"{conversation_id}.json"
        try:
            with open(conv_file, 'w', encoding='utf-8') as f:
                json.dump(conv_data, f, ensure_ascii=False, indent=2)
        except IOError as e:
            logging.error(f"Error saving conversation {conversation_id} after title update: {e}")
            return False

        # تحديث الفهرس
        if conversation_id in self.index:
            self.index[conversation_id]['title'] = new_title
            self.index[conversation_id]['last_updated'] = conv_data['last_updated']
            self.save_index()
        else:
            logging.warning(f"Conversation {conversation_id} not found in index during title update.")

        return True

    def add_tags(self, conversation_id, tags):
        """إضافة علامات للمحادثة"""
        conv_data = self.get_conversation(conversation_id)
        if not conv_data:
            return False

        if 'tags' not in conv_data:
            conv_data['tags'] = []

        for tag in tags:
            if tag not in conv_data['tags']:
                conv_data['tags'].append(tag)

        conv_data['last_updated'] = datetime.now().isoformat()

        # حفظ المحادثة
        conv_file = self.conversations_dir / f"{conversation_id}.json"
        try:
            with open(conv_file, 'w', encoding='utf-8') as f:
                json.dump(conv_data, f, ensure_ascii=False, indent=2)
        except IOError as e:
            logging.error(f"Error saving conversation {conversation_id} after adding tags: {e}")
            return False

        # تحديث الفهرس
        if conversation_id in self.index:
            self.index[conversation_id]['tags'] = conv_data['tags']
            self.index[conversation_id]['last_updated'] = conv_data['last_updated']
            self.save_index()
        else:
            logging.warning(f"Conversation {conversation_id} not found in index during tag add.")

        return True

    def get_conversation_context(self, conversation_id, last_n_messages=5):
        """الحصول على سياق المحادثة"""
        conv_data = self.get_conversation(conversation_id)
        if not conv_data:
            return ""

        messages = conv_data['messages'][-last_n_messages:]
        context = f"المحادثة: {conv_data['title']}\n\n"

        for msg in messages:
            context += f"س: {msg['prompt']}\nج: {msg['response'][:300]}...\n\n"

        return context

    def export_conversation(self, conversation_id, format='txt'):
        """تصدير محادثة"""
        conv_data = self.get_conversation(conversation_id)
        if not conv_data:
            return None

        content = None
        if format == 'txt':
            content = f"المحادثة: {conv_data['title']}\n"
            content += f"تاريخ الإنشاء: {conv_data['created_at']}\n"
            content += "=" * 50 + "\n\n"

            for i, msg in enumerate(conv_data['messages'], 1):
                content += f"الرسالة {i} - {msg['timestamp']}\n"
                content += f"السؤال: {msg['prompt']}\n"
                content += f"الإجابة: {msg['response']}\n"
                content += "-" * 30 + "\n\n"

        elif format == 'json':
            content = json.dumps(conv_data, ensure_ascii=False, indent=2)

        return content

    def cleanup_old_conversations(self, days=30):
        """تنظيف المحادثات القديمة"""
        cutoff_date = datetime.now() - timedelta(days=days)
        deleted_count = 0

        # إنشاء قائمة بالمعرفات للحذف لتجنب تعديل القاموس أثناء التكرار
        conv_ids_to_delete = []
        for conv_id, conv_info in self.index.items():
            try:
                last_updated = datetime.fromisoformat(conv_info['last_updated'])
                if last_updated < cutoff_date:
                    conv_ids_to_delete.append(conv_id)
            except ValueError as e:
                logging.error(f"Invalid date format for conversation {conv_id}: {e}")
                # قد ترغب في حذف المحادثة ذات التاريخ التالف أيضاً
                # conv_ids_to_delete.append(conv_id)

        for conv_id in conv_ids_to_delete:
            if self.delete_conversation(conv_id):
                deleted_count += 1

        return deleted_count