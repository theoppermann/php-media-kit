"""Run inside the web container with /opt/pyaaf2/venv/bin/python.

The test also supports stdin, so the test directory need not be mounted:
    docker compose exec -T web /opt/pyaaf2/venv/bin/python - < tests/python-aaf-smoke.py
"""

import importlib.metadata
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import venv

import aaf2
from aaf2.components import Filler, Sequence
from aaf2.mobs import CompositionMob


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def command_output(command):
    result = subprocess.run(command, capture_output=True, text=True)
    require(
        result.returncode == 0,
        f"Command failed: {command!r}\n{result.stdout}{result.stderr}",
    )
    return result.stdout.strip()


def main():
    expected_venv = Path("/opt/pyaaf2/venv")
    require(os.geteuid() == 33, "Run this test as the web user (UID 33)")
    require(Path(sys.prefix) == expected_venv, "Use /opt/pyaaf2/venv/bin/python")
    require(
        Path(aaf2.__file__).resolve().is_relative_to(expected_venv),
        "aaf2 was not imported from the image's pyaaf2 virtual environment",
    )

    with tempfile.TemporaryDirectory(prefix="python-aaf-smoke-", dir="/tmp") as tmp:
        workdir = Path(tmp)
        temporary_file = workdir / "temporary.txt"
        temporary_file.write_text("web-user-tempfile\n", encoding="utf-8")
        require(
            temporary_file.read_text(encoding="utf-8") == "web-user-tempfile\n",
            "Temporary file roundtrip failed",
        )

        aaf_path = workdir / "timeline.aaf"
        composition_name = "PHP Media Kit smoke test"
        with aaf2.open(str(aaf_path), "w") as aaf:
            composition = aaf.create.CompositionMob(composition_name)
            aaf.content.mobs.append(composition)
            mob_id = str(composition.mob_id)
            slot = composition.create_timeline_slot(edit_rate=25, slot_id=1)
            sequence = aaf.create.Sequence(media_kind="picture", length=25)
            sequence.components.append(aaf.create.Filler(media_kind="picture", length=25))
            slot.segment = sequence

        with aaf2.open(str(aaf_path), "r") as aaf:
            mobs = list(aaf.content.mobs)
            require(len(mobs) == 1, "AAF composition count did not survive reopening")
            composition = mobs[0]
            require(isinstance(composition, CompositionMob), "AAF mob type changed")
            require(composition.name == composition_name, "AAF composition name changed")
            require(str(composition.mob_id) == mob_id, "AAF composition ID changed")
            require(len(composition.slots) == 1, "AAF timeline slot was not persisted")
            slot = composition.slot_at(1)
            require(float(slot.edit_rate) == 25, "AAF timeline edit rate changed")
            sequence = slot.segment
            require(isinstance(sequence, Sequence), "AAF timeline sequence was not persisted")
            require(sequence.media_kind.lower() == "picture", "AAF media kind changed")
            require(sequence.length == 25, "AAF sequence length changed")
            components = list(sequence.components)
            require(len(components) == 1, "AAF sequence component count changed")
            require(isinstance(components[0], Filler), "AAF filler was not persisted")
            require(components[0].length == 25, "AAF filler length changed")

        nested_venv = workdir / "venv"
        # /tmp is mounted noexec; symlink the installed interpreter instead of
        # copying an executable into the temporary virtual environment.
        venv.EnvBuilder(with_pip=True, symlinks=True).create(nested_venv)
        nested_python = str(nested_venv / "bin/python")
        nested_prefix = command_output([nested_python, "-c", "import sys; print(sys.prefix)"])
        require(Path(nested_prefix) == nested_venv, "Creating a temporary venv failed")
        nested_pip = command_output([nested_python, "-m", "pip", "--version"])

        result = {
            "status": "ok",
            "uid": os.geteuid(),
            "python": platform.python_version(),
            "pyaaf2": importlib.metadata.version("pyaaf2"),
            "venv": str(expected_venv),
            "tmp": "/tmp",
            "aaf_bytes": aaf_path.stat().st_size,
            "temporary_venv_pip": nested_pip.split()[1],
            "checks": ["tmp-write-read", "aaf-timeline-roundtrip", "venv-with-pip"],
        }

    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
