import json
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List

class FeedbackManager:
    def __init__(self):
        self.feedback_file = Path.home() / '.gemini-enhanced' / 'feedback.json'
        self.feedback_file.parent.mkdir(parents=True, exist_ok=True)
        self._load_feedback()

    def _load_feedback(self):
        if self.feedback_file.exists():
            with open(self.feedback_file, 'r', encoding='utf-8') as f:
                try:
                    self.feedback_data = json.load(f)
                except json.JSONDecodeError:
                    self.feedback_data = []
        else:
            self.feedback_data = []

    def _save_feedback(self):
        with open(self.feedback_file, 'w', encoding='utf-8') as f:
            json.dump(self.feedback_data, f, ensure_ascii=False, indent=2)

    def add_feedback(self, solution_id: str, was_helpful: bool, error_details: Dict[str, Any]):
        feedback_entry = {
            "solution_id": solution_id,
            "was_helpful": was_helpful,
            "timestamp": datetime.now().isoformat(),
            "error_details": error_details
        }
        self.feedback_data.append(feedback_entry)
        self._save_feedback()

    def get_all_feedback(self) -> List[Dict[str, Any]]:
        return self.feedback_data

    def clear_feedback(self):
        self.feedback_data = []
        self._save_feedback()
