import sys
import os
import subprocess
from datetime import datetime

print("Uploading to Bintray (cURL) ...")

# API url
BASE_URL = "https://api.bintray.com/content/francescoceruti/LinuxShowPlayer"

# Information on the current build
API_KEY = os.environ["BINTRAY_API_KEY"]
BRANCH = os.environ["CIRCLE_BRANCH"]
COMMIT = os.environ["CIRCLE_SHA1"]
BUILD_NUM = os.environ["CIRCLE_BUILD_NUM"]

# Get file as first argument
file = sys.argv[1]
file_name, file_ext = os.path.splitext(os.path.basename(file))

# Calculate a version like 2019.04.06_60_fb00c66
version = "{}_{}_{}".format(
    datetime.now().strftime("%Y.%m.%d"), BUILD_NUM, COMMIT[:7]
)
pkg_name = "{file_name}-{branch}-{version}.{file_ext}".format(
    file_name=file_name, branch=BRANCH, version=version, file_ext=file_ext
)
upload_url = "{base_url}/ci/{version}/{branch}/{pkg_name}".format(
    base_url=BASE_URL, version=version, branch=BRANCH, pkg_name=pkg_name
)

# Execute the cURL command
subprocess.run(
    (
        "curl",
        "-T",
        file,
        "-ufrancescoceruti:{}".format(API_KEY),
        upload_url,
    ),
    capture_output=True,
    check=True,
)
