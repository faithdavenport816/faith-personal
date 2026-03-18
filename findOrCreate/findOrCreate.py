import pandas as pd
import requests
import time
import os
import base64
from google.cloud import bigquery

# CONFIGURABLE VARIABLE ASSIGNMENT

API_USER = "2026CoordinatedActionPlatformAPIemails"
state_code = os.getenv("STATE_CODE")
print(state_code)
API_KEY_ENV_VAR_PREFIX = "VAN_{state_code}_TOKEN"
BQ_PROJECT_ID = "demsdscc"
BQ_SOURCE_TABLE = "commons.findOrCreatetestdata"
BQ_RESULTS_TABLE = "commons.findOrCreatetestdata_results"

# -------------------------------------------------------------------------
# Endpoints
VAN_FOC_ENDPOINT = "https://api.securevan.com/v4/people/findOrCreate"
MAX_RETRIES = 3
INITIAL_WAIT = 2.0  # seconds, doubles on each retry


# --- Functions ---
def get_bq_data(table):
    """
    Query a BigQuery table
    """
    client = bigquery.Client()
    sql_query = f"""
        SELECT * FROM {table}
    """
    df = client.query_and_wait(sql_query).to_dataframe()
    client.close()
    return df


def construct_foc_payload(data):
    """
    Build the VAN findOrCreate API payload from a row of data.
    Normalizes keys to lowercase and skips null/missing fields.
    """
    data_lower = {k.lower(): v for k, v in data.items()}
    payload = {}

    if "firstname" in data_lower and data_lower["firstname"]:
        payload["firstName"] = data_lower["firstname"]
    if "lastname" in data_lower and not pd.isna(data_lower["lastname"]):
        payload["lastName"] = data_lower["lastname"]
    if "myc_van_id" in data_lower and not pd.isna(data_lower["myc_van_id"]):
        payload["vanId"] = data_lower["myc_van_id"]

    if (
        "email" in data_lower
        and data_lower["email"]
        and not pd.isna(data_lower["email"])
    ):
        payload["emails"] = [{"email": data_lower["email"]}]

    if (
        "phonenumber" in data_lower
        and data_lower["phonenumber"]
        and not pd.isna(data_lower["phonenumber"])
    ):
        payload["phones"] = [
            {
                "phoneNumber": str(int(data_lower["phonenumber"])),
                "phoneType": "Cell",
            }
        ]

    address = {}
    if "streetaddress" in data_lower and not pd.isna(data_lower["streetaddress"]):
        address["addressLine1"] = data_lower["streetaddress"]
    if "city" in data_lower and not pd.isna(data_lower["city"]):
        address["city"] = data_lower["city"]
    if "state_code" in data_lower and not pd.isna(data_lower["state_code"]):
        address["stateOrProvince"] = data_lower["state_code"]
    if "ziporpostalcode" in data_lower and not pd.isna(data_lower["ziporpostalcode"]):
        address["zipOrPostalCode"] = data_lower["ziporpostalcode"]
    if address:
        address["countryCode"] = "US"
        payload["addresses"] = [address]

    return payload


def get_auth(state_code):
    """
    Build the Basic Auth token for the VAN API.
    Mode is 'myc' (MyCampaign) so we add the "|1" suffix to the API key.
    """
    api_user = API_USER
    api_key = os.getenv(API_KEY_ENV_VAR_PREFIX.format(state_code=state_code)) + "|1"
    if api_user is None or api_key is None:
        raise ValueError(f"API credentials not found for state {state_code}")
    encoded = base64.b64encode(f"{api_user}:{api_key}".encode()).decode()
    return encoded


def find_or_create_person(row, max_retries=MAX_RETRIES, initial_wait=INITIAL_WAIT):
    """
    Call VAN findOrCreate for a single person.
    Returns a dict with vanId and metadata on success, None after max retries.
    200 = matched existing person, 201 = created new person.
    """
    auth = get_auth(row["state_code"])
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": f"Basic {auth}",
    }
    payload = construct_foc_payload(row)

    for attempt in range(max_retries):
        try:
            response = requests.post(VAN_FOC_ENDPOINT, json=payload, headers=headers)
            if response.status_code in (200, 201):
                response_data = {
                    "vanId": response.json().get("vanId"),
                    "status": "success",
                    "error_code": response.status_code,
                    "state_code": row["state_code"],
                }
                return response_data
            else:
                print(
                    f"Attempt {attempt + 1} failed with status code {response.status_code}. Retrying..."
                )
                print(f"Failed payload: {payload}")
                time.sleep(initial_wait * 2**attempt)
        except requests.RequestException as e:
            print(f"{e}. Retrying...")
            time.sleep(initial_wait * 2**attempt)

    print("Giving up.")
    return None


def write_results_to_bq(responses_df, project_id, destination):
    """
    Send results to BigQuery.
    """
    responses_df.to_gbq(
        destination_table=destination,
        project_id=project_id,
        if_exists="append",
        progress_bar=True,
    )


def main(bq_table, state_code, project_id, destination_table):
    df = get_bq_data(bq_table, state_code)
    responses = []
    for index, row in df.iterrows():
        print(index)
        response_data = find_or_create_person(row)
        if response_data:
            responses.append(response_data)
            print(response_data)
    responses_df = pd.DataFrame(responses)
    write_results_to_bq(
        responses_df, project_id=project_id, destination=destination_table
    )


if __name__ == "__main__":
    main(
        bq_table=BQ_SOURCE_TABLE,
        state_code={state_code},
        project_id=BQ_PROJECT_ID,
        destination_table=BQ_RESULTS_TABLE,
    )
