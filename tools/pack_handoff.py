"""Package the current illustrated build; require fresh runtime evidence."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name("pack_illustrated_handoff.py")),run_name="__main__")
