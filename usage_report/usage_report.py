"""Generate partition usage reports."""
import argparse
import calendar
import datetime
import io
import subprocess

import numpy
import pandas
import tabulate

parser = argparse.ArgumentParser(__doc__)
parser.add_argument(
    "-p",
    "--partition",
    type=str,
    nargs="+",
    required=True,
    help="Name of partition",
)
parser.add_argument(
    "-m",
    "--month",
    type=str,
    required=True,
    help="Month for report in YYYY-MM format",
)
parser.add_argument(
    "-o",
    "--output",
    type=str,
    required=True,
    help="Output file",
)
args = parser.parse_args()

# figure out times for the reporting period
start_date = datetime.datetime.strptime(args.month, "%Y-%m")
_,max_report_days = calendar.monthrange(start_date.year, start_date.month)
max_report_period = datetime.timedelta(days=max_report_days, seconds=-1)
today = datetime.datetime.now()
if today > start_date and (today - start_date) < max_report_period:
    end_date = today
else:
    end_date = start_date + max_report_period
report_hours = (end_date - start_date).total_seconds()/3600.

capacity = {
    "phase1": {
        "chen_std": {
            "aja0056_lab": 2,
            "cak0071_lab": 2,
            "mph0043_lab": 2,
            "szc0113_lab": 1,
            "department": 4,
        },
        "chen_bg2": {
            "rjp0029_lab": 1,
            "szc0113_lab": 2,
            "department": 2,
        },
    },
    "phase2": {
        "chen_std": {
            "cak0071_lab": 4,
            "mph0043_lab": 6,
            "rjp0029_lab": 5,
            "szc0113_lab": 1,
            "department": 10,
        },
        "chen_bg2": {
            "rjp0029_lab": 1,
            "szc0113_lab": 2,
            "department": 2,
        },
    },
}
phase2_launch = datetime.datetime(2023, 3, 9)
if start_date < phase2_launch and end_date < phase2_launch:
    capacity = capacity["phase1"]
else:
    capacity = capacity["phase2"]
def get_capacity_key(account):
    """Get the capacity key associated with an account."""
    if account in ("edenmar_lab", "aja0056_lab"):
        account_key = "department"
    else:
        account_key = account
    return account_key

for partition in args.partition:
    try:
        nodes = capacity[partition]
    except KeyError:
        raise ValueError(f"Partition {partition} not found")
    num_nodes = sum(nodes.values())
    # 48 cores per node for everything we have
    num_cores = 48*num_nodes

    # run sacct to pull usage of our partitions
    result = subprocess.run([
        "sacct",
        "-X",
        "--allusers",
        "--partition", partition,
        "--starttime", f"{start_date:%Y-%m-%d %H:%M:%S}",
        "--endtime", f"{end_date:%Y-%m-%d %H:%M:%S}",
        "--format", "Account,CPUTimeRAW",
        "--parsable",
        "--delimiter", ","
    ], check=True, capture_output=True, text=True)
    usage_data = pandas.read_csv(io.StringIO(result.stdout))
    # slurm adds an empty last column, drop it
    usage_data = usage_data.iloc[:,:-1]

    # compute core-hour capacity, total usage, and usage by group
    core_hours = {}
    core_hours["capacity"] = num_cores*report_hours
    core_hours["total"] = numpy.sum(usage_data["CPUTimeRAW"])/3600.
    accounts = sorted(list(set(usage_data["Account"])))
    account_core_hours = {}
    for account in accounts:
        account_key = get_capacity_key(account)
        if account_key not in account_core_hours:
            account_core_hours[account_key] = 0
        account_core_hours[account_key] += numpy.sum(usage_data.loc[usage_data["Account"] == account,"CPUTimeRAW"])/3600.
    assert sum(account_core_hours.values()) == core_hours["total"], "Some jobs were not assigned to a known account"

    # generate a table of results in Markdown format
    usage_report = []
    usage_report.append([
        "*total*",
        num_nodes,
        core_hours["total"],
        100*core_hours["total"]/core_hours["capacity"],
    ])
    for account in nodes:
        account_hours = account_core_hours.get(account, 0)
        if core_hours["total"] > 0:
            percent_total = 100*account_hours/core_hours["total"]
        else:
            percent_total = 0

        usage_report.append([
            f"`{account}`",
            nodes[account],
            account_hours,
            100*account_hours/core_hours["capacity"],
            percent_total,
        ])
    report_table = tabulate.tabulate(
        usage_report,
        headers=["account", "nodes reserved", "CPU hours used", "% capacity used", "% total used"],
        floatfmt=".1f",
        tablefmt="github",
    )
    with open(args.output, "a") as f:
        f.write(f"`{partition}` from {start_date:%Y-%m-%d} to {end_date:%Y-%m-%d}" + "\n")
        f.write("\n" + report_table + "\n\n")
