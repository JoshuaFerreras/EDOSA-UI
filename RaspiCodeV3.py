import random
import string
from datetime import datetime, timedelta
import requests

# Read the data from the text file
with open(r"", "r") as file:  # place the path to the text file here
    lines = file.readlines()

# Extract the column names from the first row and remove '\n'
column_names = lines[0].strip().split("\t\t")

data_lines = lines[5:]

# Remove '\n' from each line and split the data using ','
data = [line.strip().split("\t\t") for line in data_lines]

userID = data[0][0]
result = {}
for i in range(3, len(column_names)):
    column_values = []
    for x in range(len(data)):
        column_values.append(float(data[x][i]))
    result[column_names[i]] = column_values
timestamp = []
# Assuming data is your list
for i in range(len(data)):
    # Convert string to datetime object
    timestamp.append(
        datetime.strptime(
            data[i][1], "%I:%M:%S %p").time().strftime("%H:%M:%S")
    )
result["timestamp"] = timestamp
therm_data = str(result["Temp"])
ecg_data = str(result["ECG"])
airflow_data = str(result["AirFlow"])
snore_data = str(result["Snore"])
spo2_data = str(result["SpO2"])
hr_data = str(result["PulseRate"])
timestamp_data = str(result["timestamp"])
print("Data being created")
data_dict = {
    "UserID": userID,
    "Temp": therm_data,
    "ECG": ecg_data,
    "AirFlow": airflow_data,
    "Snore": snore_data,
    "SpO2": spo2_data,
    "PulseRate": hr_data,
    "TimeIn": f"{data[0][2]} {result['timestamp'][0]}",
    "TimeOut": f"{data[-1][2]} {result['timestamp'][-1]}",
    "Timestamp": timestamp_data,
}
print("Data created")

# ! change to reflect the ip address of the server
url = "http://localhost:5000/insert"

# Send the request and measure the time taken
print("Sending request...")
start = datetime.now()
response = requests.post(url, json=data_dict)
end = datetime.now()
duration = end - start
print("Request completed in", duration.total_seconds(), "seconds")

print(response.status_code, response.reason, response.text)
