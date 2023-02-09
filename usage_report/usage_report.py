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

for partition in args.partition:
    # run sinfo to get number of cores in partition
    # this assumes the size of the partition has not changed
    result = subprocess.run([
        "sinfo",
        "-s",
        "--partition", partition,
        "--format", "%C",
        "--noheader"
    ], check=True, capture_output=True, text=True)
    output = result.stdout.strip()
    if len(output) == 0:
        raise ValueError(f"Partition {partition} not found")
    num_cores = int(output.split("/")[-1])

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
    if usage_data.shape[0] == 0:
        raise ValueError(f"No job data found for partition {partition}")
    # slurm adds an empty last column, drop it
    usage_data = usage_data.iloc[:,:-1]

    # compute core-hour capacity, total usage, and usage by group
    core_hours = {}
    core_hours['capacity'] = num_cores*report_hours
    core_hours['total'] = numpy.sum(usage_data["CPUTimeRAW"])/3600.
    accounts = sorted(list(set(usage_data["Account"])))
    for account in accounts:
        core_hours[account] = numpy.sum(usage_data.loc[usage_data["Account"] == account,"CPUTimeRAW"])/3600.

    # generate a table of results in Markdown format
    usage_report = []
    usage_report.append([
        "*total*",
        core_hours["total"],
        100*core_hours["total"]/core_hours["capacity"],
    ])
    for account in accounts:
        usage_report.append([
            f"`{account}`",
            core_hours[account],
            100*core_hours[account]/core_hours["capacity"],
            100*core_hours[account]/core_hours["total"],
        ])
    report_table = tabulate.tabulate(
        usage_report,
        headers=["account","CPU hours","% capacity","% total"],
        floatfmt=".1f",
        tablefmt="github",
    )
    with open(args.output, "a") as f:
        f.write(f"`{partition}` from {start_date:%Y-%m-%d} to {end_date:%Y-%m-%d}" + "\n")
        f.write("\n" + report_table + "\n\n")
