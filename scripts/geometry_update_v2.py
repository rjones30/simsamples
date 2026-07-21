"""
geometry_update.py  --  Upload XML files into CCDB using the Python API.

The problem: One wants to hold an XML in CCDB. But the 'add' command only
             accepts tabled (delimited text) files, which breaks for XML content.
The solution: Use the ccdb Python API to load such custom data directly.

Usage
-----
The table must already exist in CCDB. To create it (one-time setup):
    ccdb mktbl /GEOMETRY/Material_HDDS.xml -r 1 xml=string "created with hdds_2_ccdb.py"

To check the table exists:
    ccdb info /GEOMETRY/Material_HDDS.xml

To verify data was added:
    ccdb vers /GEOMETRY/Material_HDDS.xml

To dump without the ccdb comment header (useful for diffing):
    ccdb dump --no-comments /GEOMETRY/Material_HDDS.xml > out.xml

Connection strings
------------------
MySQL:  "mysql://ccdb_user@hallddb.jlab.org/ccdb"
SQLite: "sqlite:////absolute/path/to/ccdb.sqlite"   (4 slashes: 3 from ://, 1 for root)

Rewritten for Python 3 by R.T. Jones, 2026.
Original Python 2 version by jonesrt, ~2018.
"""

import sys
import io
import ccdb

# ── Configuration ─────────────────────────────────────────────────────────────

DRY_RUN = False   # Set to False to actually write to the database.

CONNECTION = "sqlite:////home/www/docs/halld/simsamples/config/ccdb_fixed_CarbonFiberEpoxy-7-2-2026.sqlite"
# CONNECTION = "mysql://ccdb_user@hallddb.jlab.org/ccdb"

AUTHOR = "jonesrt"

# ── Provider setup ────────────────────────────────────────────────────────────

provider = ccdb.AlchemyProvider()
provider.connect(CONNECTION)
provider.authentication.current_user_name = AUTHOR

# ── Core functions ────────────────────────────────────────────────────────────

def dry_run_warning():
    if DRY_RUN:
        print("  [dry run] To execute the above, set DRY_RUN = False.")


def upload(tablepath, filename, runs, var, comment):
    """
    Upload the contents of filename into CCDB table at tablepath,
    for the given run range and variation.

    Parameters
    ----------
    tablepath : str   e.g. "/GEOMETRY/Material_HDDS.xml"
    filename  : str   path to the local XML file to upload
    runs      : tuple (min_run,) or (min_run, max_run); 0 means INFINITE_RUN
    var       : str   variation name, e.g. "default"
    comment   : str   log comment
    """
    xml_content = io.open(filename, "r", encoding="utf-8").read()
    tabled_data = [[xml_content]]

    # Normalise run range
    if len(runs) == 1:
        min_run, max_run = runs[0], ccdb.INFINITE_RUN
    elif runs[1] == 0:
        min_run, max_run = runs[0], ccdb.INFINITE_RUN
    else:
        min_run, max_run = runs[0], runs[1]

    print(f"upload({tablepath!r}, {filename!r}, runs={min_run}-{max_run}, "
          f"var={var!r}, comment={comment!r})")

    if not DRY_RUN:
        provider.create_assignment(
            data=tabled_data,
            path=tablepath,
            variation_name=var,
            min_run=min_run,
            max_run=max_run,
            comment=comment,
        )
    dry_run_warning()


def delete(assignment_id):
    """
    Delete an assignment by id.  Useful for undoing a mistaken upload.
    """
    print(f"delete_assignment({assignment_id})")
    if not DRY_RUN:
        provider.delete_assignment(provider.get_assignment_by_id(assignment_id))
    dry_run_warning()


def cat(assignment_id, outfile):
    """
    Write the XML content of an assignment to a local file.
    """
    print(f"cat assignment {assignment_id} -> {outfile!r}")
    if not DRY_RUN:
        content = provider.get_assignment_by_id(assignment_id).constant_set.data_table[0][0]
        with open(outfile, "w", encoding="utf-8") as fout:
            fout.write(content)
    dry_run_warning()


def mcat(lsfile):
    """
    Dump all assignments listed in lsfile to individual XML files named
    <assignment_id>.xml.  lsfile format: first line is the table path,
    second line is a header, then one assignment per line as produced by
    'ccdb vers'.
    """
    with open(lsfile) as fin:
        tablepath = fin.readline().rstrip()
        next(fin)   # skip header line
        for line in fin:
            assignment_id = int(line.split()[0])
            outfile = f"{assignment_id}.xml"
            cat(assignment_id, outfile)


def mpush(lsfile):
    """
    Upload a set of XML files listed in lsfile.  Each XML file must be
    named <assignment_id>.xml.  lsfile format: first line is the table
    path, second line is a header, then one assignment per line as
    produced by 'ccdb vers'.
    """
    with open(lsfile) as fin:
        tablepath = fin.readline().rstrip()
        next(fin)   # skip header line
        for line in fin:
            parts = line.rstrip().split()
            assignment_id = int(parts[0])
            var = parts[5]
            raw_runs = parts[6].split("-")
            runs = []
            for r in raw_runs:
                r = r.rstrip("L")
                if r == "inf":
                    runs.append(0)
                else:
                    runs.append(int(r))
            comment = " ".join(parts[7:])
            filename = f"{assignment_id}.xml"
            upload(tablepath, filename, tuple(runs), var, comment)


def mdel(lsfile):
    """
    Delete all assignments listed in lsfile.  lsfile format as above.
    """
    with open(lsfile) as fin:
        tablepath = fin.readline().rstrip()
        next(fin)   # skip header line
        for line in fin:
            assignment_id = int(line.split()[0])
            delete(assignment_id)


# ── Main / example usage ──────────────────────────────────────────────────────

if __name__ == "__main__":
    # Example: upload a fixed Material_HDDS.xml into the sqlite file,
    # variation 'default', run 150000 to infinity.
    #
    # Set DRY_RUN = False above when you are ready to commit.

    upload(
        tablepath="/GEOMETRY/Material_HDDS.xml",
        filename="Material_HDDS.xml",
        runs=(1, 999999),
        var="default",
        comment="fix CarbonFiberEpoxy duplicate component bug",
    )
