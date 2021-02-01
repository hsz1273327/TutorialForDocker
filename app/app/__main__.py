import time
from pathlib import Path
from hashlib import md5
from typing import Union, Dict
from watchdog.observers import Observer
from watchdog.events import (
    FileSystemEventHandler,
    FileCreatedEvent,
    DirCreatedEvent,
    DirModifiedEvent,
    FileModifiedEvent
)


class UpdateIndexes(FileSystemEventHandler):
    """
    Base file system event handler that you can override methods from.
    """
    latest: Dict[str, bytes]

    def __init__(self, ) -> None:
        self.latest = {}

    def on_modified(self, event: Union[DirModifiedEvent, FileModifiedEvent]) -> None:
        if isinstance(event, FileModifiedEvent):
            with open(event.src_path) as f:
                content = f.read()
            if content:
                m = md5()
                m.update(content.encode("utf-8"))
                nowmd5 = m.digest()
                lastmd5 = self.latest.get(event.src_path)
                if lastmd5:
                    if lastmd5 != nowmd5:
                        self.latest[event.src_path] = nowmd5
                        print(content)
                else:
                    self.latest[event.src_path] = nowmd5
                    print(content)


if __name__ == "__main__":
    print("start")
    p = Path("/data")
    for i in p.iterdir():
        print(str(i))
    observer = Observer()
    fsevent_handler = UpdateIndexes()
    observer.schedule(fsevent_handler, "/data", recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(1)
    finally:
        observer.stop()
        observer.join()
