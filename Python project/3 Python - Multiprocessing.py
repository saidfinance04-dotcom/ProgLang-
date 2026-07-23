from concurrent.futures import ProcessPoolExecutor
import multiprocessing
import time


def cpu_heavy_task(n):
    total = 0
    for i in range(n):
        total += i * i
    return total


def main():
    # 24 tasks so chunking across workers is visible.
    work_items = [80_000_000] * 24

    with ProcessPoolExecutor(max_workers=24) as executor:
        results = list(executor.map(cpu_heavy_task, work_items))
    print(results)


if __name__ == "__main__":
    multiprocessing.freeze_support()  # Windows-friendly script entrypoint.
    main()
