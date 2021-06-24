from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.interval import IntervalTrigger
from pyloggerhelper import log
from pytz import timezone
locale = timezone('Asia/Shanghai')


def applog() -> None:
    log.warn("ping")


def eventlog() -> None:
    log.warn("help")


def main() -> None:
    log.initialize_for_app(app_name="example-app", log_level="WARN")
    scheduler = BlockingScheduler(logger=log, timezone=locale)
    scheduler.add_job(applog, trigger=IntervalTrigger(seconds=3))
    scheduler.add_job(eventlog, trigger=IntervalTrigger(seconds=5))
    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        log.info("app stoped")


if __name__ == "__main__":
    main()
