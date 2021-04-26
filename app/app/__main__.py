import time
from pathlib import Path
from hashlib import md5
from typing import Union, Dict
from pyloggerhelper import log
#from watchdog.observers import Observer
from watchdog.observers.polling import PollingObserver as Observer
from watchdog.events import (
    FileSystemEventHandler,
    FileCreatedEvent,
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
        log.info("handdler get event", get_event=event)
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
                        log.info("get file modified", p=event.src_path, content=content)
                else:
                    self.latest[event.src_path] = nowmd5
                    log.info("get file modified", p=event.src_path, content=content)


if __name__ == "__main__":
    log.initialize_for_app(app_name="standalone_colume_nfs", log_level="DEBUG")
    log.info("start", p="/data")
    p = Path("/data")
    for i in p.iterdir():
        if i.is_dir():
            log.info("there are dir", dir_name=i)
        else:
            log.info("there are file", file_name=i)
    observer = Observer()
    fsevent_handler = UpdateIndexes()
    observer.schedule(fsevent_handler, "/data/test", recursive=True)
    log.info("watch file change", dir_name="/data/test")
    observer.start()
    try:
        while True:
            time.sleep(1)
    finally:
        observer.stop()
        observer.join()
        log.info("watch file change process fin", dir_name="/data/test")
