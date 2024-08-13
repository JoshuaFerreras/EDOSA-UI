import processing.serial.*;

import processing.serial.Serial;
import java.io.*;
import javax.swing.JOptionPane;
import java.text.SimpleDateFormat;
import java.util.Date;

Serial myPort;
float[] sensorValues = new float[6];
String[] labels = {"UserID", "Timestamp", "Date", "ECG", "AirFlow", "Snore", "Temp", "SpO2", "PulseRate"};
int numRows = 2;
int numColumns = 3;
float boxSpacingX;
float boxSpacingY;

boolean isFirstPage = true;
boolean isReadingStarted = false;
boolean isReadingPaused = false;
boolean stopRequested = false;
boolean showStopConfirmation = false;
Button saveButton;
Button startButton;
Button stopButton;
Button enterButton;
Button pauseButton;
Button resumeButton;
Button logoutButton;

TextField userIdField;
PrintWriter output;
boolean isFirstDataEntry = true;

boolean displaySensorData = false;

Keyboard keyboard;

PImage backgroundImage; // Added variable for background image

// Timer variables
boolean timerStarted = false;
int elapsedTime = 0;
int previousTime = 0;

void setup() {
  size(800, 480);
  //fullScreen();
  String portName = "COM3";
  myPort = new Serial(this, portName,9600);

  float buttonWidth = 126;
  float buttonHeight = 40;
 
  enterButton = new Button(width / 1.85 - buttonWidth / 3, height - 75, buttonWidth, buttonHeight, "Enter");
  enterButton.onClick(() -> {
    if (!userIdField.getValue().isEmpty()) {
      displaySensorData = true;
      enterButton.setActive(false); // Deactivate the button
      resetSensorValues();
      // Reset sensor values to zero
    }
  });

  stopButton = new Button(width - 600, height - 30, buttonWidth, buttonHeight, "Stop");
  stopButton.onClick(() -> {
    if (isReadingStarted) {
      showStopConfirmation = true; // Show the stop confirmation message
    }
  });

  saveButton = new Button(width - 466, height - 30, buttonWidth, buttonHeight, "Save");
  saveButton.onClick(() -> {
    if (isReadingStarted) {
      saveDataToFile();
      JOptionPane.showMessageDialog(null, "Data saved successfully.", "Save", JOptionPane.INFORMATION_MESSAGE);
    }
  });

  startButton = new Button(width - 735, height - 30, buttonWidth, buttonHeight, "Start");
  startButton.onClick(() -> {
    if (!isReadingStarted && !userIdField.getValue().isEmpty()) {
      isReadingStarted = true;
      isReadingPaused = false;
      // Start the timer
      elapsedTime = 0;
      startTimer();
    }
  });

  pauseButton = new Button(width - 331, height - 30, buttonWidth, buttonHeight, "Pause");
  pauseButton.onClick(() -> {
    if (isReadingStarted && !isReadingPaused) {
      isReadingPaused = true;
      pauseDataCapture();
      // Stop the timer
      stopTimer();
    }
  });

  resumeButton = new Button(width - 200, height - 30, buttonWidth, buttonHeight, "Resume");
  resumeButton.onClick(() -> {
    if (isReadingStarted && isReadingPaused) {
      isReadingPaused = false;
      resumeDataCapture();
      // Start the timer
      startTimer();
    }
  });

  logoutButton = new Button(width - 66, height - 30, buttonWidth, buttonHeight, "Logout");
  logoutButton.onClick(() -> {
    if (isReadingStarted) {
      isReadingStarted = false;
      isReadingPaused = false;
      displaySensorData = false;
      enterButton.setActive(true); // Activate the Enter button
      // Reset sensor values to zero
      resetSensorValues();
      // Stop the timer
      stopTimer();
    }
    logOut(); // Call the logOut() function
  });

  boxSpacingX = width / numColumns + 2;
  boxSpacingY = (height - 200) / numRows + 65;

  userIdField = new TextField(width / 2 - 100, height - 80, 200, 30);

  output = createWriter("data.txt");
  saveDataToFile(true); // Write labels initially

  keyboard = new Keyboard();

  // Load the background image
  backgroundImage = loadImage("edosa.png");
}

void draw() {
  background(0);

  if (isFirstPage) {
    drawFirstPage();
  } else {
    drawKeyboardPage();
  }

  // Check if stop confirmation message should be displayed
  if (showStopConfirmation) {
    showStopConfirmation = false; // Reset the flag
    executePythonScript();
    int dialogResponse = JOptionPane.showOptionDialog(null, "Data stopped successfully", "Stop", JOptionPane.OK_CANCEL_OPTION, JOptionPane.INFORMATION_MESSAGE, null, null, null);

    if (dialogResponse == JOptionPane.OK_OPTION) {
      stopRequested = true;
    }
  }

  // Check if stop is requested
  if (stopRequested) {
    isReadingStarted = false;
    stopDataCapture();
    stopRequested = false; // Reset the stopRequested flag
    // Reset sensor values to zero
    resetSensorValues();
    // Stop the timer
    stopTimer();
  }

  // Update the timer
  updateTimer();
}

void drawFirstPage() {
  // Display the background image
  image(backgroundImage, 0, 0, width, height);

  // Display the "BEGIN" button
  float buttonWidth = 170;
  float buttonHeight = 60;
  float buttonX = width / 2 - buttonWidth / 13;
  float buttonY = height - 80; // Adjust the Y position to the bottom
  float cornerRadius = 9;

  rectMode(CENTER);
  stroke(255);
  strokeWeight(1);
  fill(0, 0, 255);
  rect(buttonX, buttonY, buttonWidth, buttonHeight, cornerRadius);

  fill(255, 255, 255);
  textAlign(CENTER, CENTER);
  textSize(23);
  text("BEGIN", buttonX, buttonY);

  // Check if the "BEGIN" button is clicked
  if (mouseX >= buttonX - buttonWidth / 2 && mouseX <= buttonX + buttonWidth / 2 &&
      mouseY >= buttonY - buttonHeight / 2 && mouseY <= buttonY + buttonHeight / 2) {
    if (mousePressed) {
      isFirstPage = false; // Switch to the keyboard page
      backgroundImage = null; // Remove the background image
    }
  }
}

void drawKeyboardPage() {
  if (!displaySensorData) {
    enterButton.display();
    userIdField.display();
    keyboard.display();
  } else {
    if (isReadingStarted && !isReadingPaused) {
      while (myPort.available() > 0) {
        String val = myPort.readStringUntil('\n');
        if (val != null && !val.trim().isEmpty()) {
        println("Received value: " + val);
        String[] values = val.trim().split("\t");
          if (values.length >= 6) {
            try {
              for (int i = 0; i < 6; i++) {
                if (!values[i].isEmpty()) {
                  sensorValues[i] = Float.parseFloat(values[i]);
                }
              }
            } catch (NumberFormatException e) {
              // Handle invalid data, e.g., log or ignore the data.
              println("Error parsing sensor values: " + e.getMessage());
            }
          } else {
            // Handle incorrect number of values in the data.
            println("Incorrect number of sensor values: " + val);
          }
        }
      }
      saveDataToFile(false); // Save data without including the header row
    }

    // Display sensor data boxes
  for (int i = 3; i < 9; i++) {  // Start from index 2 to skip UserID and Timestamp
    int row = (i - 3) / numColumns;
    int col = (i - 3) % numColumns;

    float x = col * boxSpacingX + boxSpacingX / 2.03;
    float y = row * boxSpacingY + boxSpacingY / 2 + 20;

    drawBox(x, y, sensorValues[i - 3], labels[i]); // Adjusted index to skip UserID and Timestamp
}

    stopButton.display();
    saveButton.display();
    startButton.display();
    pauseButton.display();
    resumeButton.display();
    logoutButton.display();

    // Display elapsed time when the "Start" button is clicked
    if (isReadingStarted) {
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      String timeStr = getTimeString();
      text("Current Time: " + timeStr, width / 2 - 100, height - 470);
    }

    // Display the elapsed time
    if (isReadingStarted) {
      fill(0, 255, 0);
      textSize(20);
      textAlign(CENTER, CENTER);
      String elapsedTimeStr = getElapsedTime();
      text("Elapsed Time: " + elapsedTimeStr, width / 2 + 111, height - 470);
    }
  }
}

void drawBox(float x, float y, float value, String label) {
  rectMode(CENTER);
  stroke(17, 74, 156);
  strokeWeight(2);

  fill(0);
  rect(x, y, boxSpacingX - 25, boxSpacingY - 40);

  if (label.equals("SpO2") && value <= 90) {
    fill(255, 0, 0);
    textSize(40);
    text(value, x, y - 20);
    textSize(20);
    text("Too Low", x, y + 20);
  } else {
    fill(255);
    textSize(70);
    text(value, x, y);
  }

  fill(255, 255, 0);
  textSize(20);
  text(label, x, y + boxSpacingY / 4);
}
class Button {
  float x, y, width, height;
  String label;
  Runnable onClick;
  boolean active = true; // Track button activity

  Button(float x, float y, float width, float height, String label) {
    this.x = x;
    this.y = y-12;
    this.width = width;
    this.height = height;
    this.label = label;
  }

  void display() {
      if (active) { // Only display if the button is active
      rectMode(CENTER);
      stroke(255);
      strokeWeight(1);

      // Set button colors based on label
      if (label.equals("Start")) {
        fill(153, 204, 255); // Blue color for Start button
      } else if (label.equals("Stop")) {
        fill(255, 0, 0); // Red color for Stop button
      } else if (label.equals("Save")) {
        fill(255, 165, 0); // Orange color for Save button
      } else if (label.equals("Pause")) {
        fill(255, 255, 0); // Yellow color for Pause button
      } else if (label.equals("Resume")) {
        fill(51, 255, 51); // Light green color for Resume button
      } else if (label.equals("Logout")) {
        fill(128, 128, 128); // Gray color for Logout button
      } else if (label.equals("Enter")) {
        fill(51, 51, 255); // Blue color for Enter button
      } else {
        fill(0, 0, 255); // Default color for other buttons
      }

      rect(x, y, width, height);

      fill(0); // Set text color to white
      textAlign(CENTER, CENTER);
      textSize(20);
      text(label, x, y);
    }
  }

  void onClick(Runnable onClick) {
    this.onClick = onClick;
  }

  void handleMouseClick() {
    if (active && onClick != null && mouseX >= x - width / 2 && mouseX <= x + width / 2 && mouseY >= y - height / 2 && mouseY <= y + height / 2) {
      onClick.run();
    }
  }

  void setActive(boolean active) {
    this.active = active;
  }
}

class TextField {
  float x, y, width, height;
  String value = "";

  TextField(float x, float y, float width, float height) {
    this.x = x + 100;
    this.y = y - 355;
    this.width = width;
    this.height = height;
   
  }

  void display() {
    rectMode(CENTER);
    stroke(255);
    strokeWeight(1);
    fill(255);
    rect(x, y, width, height);

    textAlign(CENTER, CENTER);
    textSize(20);
    fill(0);
    text(value, x, y);
  }

  String getValue() {
    return value;
  }
}

void resetSensorValues() {
  for (int i = 0; i < sensorValues.length; i++) {
    sensorValues[i] = 0;
  }
}

void mouseClicked() {
  if (isFirstPage) {
    // Check if the "BEGIN" button is clicked
    float buttonWidth = 130;
    float buttonHeight = 40;
    float buttonX = width / 2 - buttonWidth / 2;
    float buttonY = height / 2 - buttonHeight / 2;
    float cornerRadius = 10;

    if (mouseX >= buttonX - buttonWidth / 2 && mouseX <= buttonX + buttonWidth / 2 &&
        mouseY >= buttonY - buttonHeight / 2 && mouseY <= buttonY + buttonHeight / 3) {
      isFirstPage = false; // Switch to the keyboard page
      backgroundImage = null; // Remove the background image
    }
  } else {
    enterButton.handleMouseClick();
    stopButton.handleMouseClick();
    saveButton.handleMouseClick();
    startButton.handleMouseClick();
    pauseButton.handleMouseClick();
    resumeButton.handleMouseClick();
    logoutButton.handleMouseClick(); // Call the handleMouseClick() method for logout button
    keyboard.handleMouseClick();
  }
}

void stopDataCapture() {
  println("Data capture stopped.");
}

void pauseDataCapture() {
  println("Data capture paused.");
}

void resumeDataCapture() {
  println("Data capture resumed.");
}

void saveDataToFile() {
  saveDataToFile(true); // By default, include the header row
}

void saveDataToFile(boolean includeHeader) {
  if (output != null) {
    // Check if it is the first data entry and header is to be included
    if (isFirstDataEntry && includeHeader) {
      // Write the header row
      for (int i = 0; i < labels.length; i++) {
        output.print(labels[i]);
        if (i < labels.length - 1) {
          output.print("\t\t");
        }
      }
      output.println();
      isFirstDataEntry = false; // Set the flag to false after writing the header row
    }

    // Write the UserID, Timestamp, and Date
    output.print(userIdField.getValue());
    output.print("\t\t");
    output.print(getTimeString());
    output.print("\t\t");
    output.print(getDateString());
    output.print("\t\t");

    // Write the sensor values excluding UserID, Timestamp, and Date
    for (int i = 3; i < labels.length; i++) {
      output.print(sensorValues[i - 3]);
      if (i < labels.length - 1) {
        output.print("\t\t");
      }
    }

    output.println(); // Add this line to move to the next line after writing sensor values
    output.flush(); // Flush the output buffer
  }
}

String getDateString() {
  SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
  Date date = new Date();
  return dateFormat.format(date);
}

void executePythonScript() {
  try {
    String scriptPath = "/Users/anton/OneDrive/Desktop/Mica/RaspiCodeV2.py";
    Process process = Runtime.getRuntime().exec("python " + scriptPath);

    // Read the output from the script
    BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
    String line;
    StringBuilder output = new StringBuilder();

    while ((line = reader.readLine()) != null) {
      output.append(line).append("\n");
    }

    int exitCode = process.waitFor();
    if (exitCode == 0) {
      // Script executed successfully
      println("Script executed successfully.");
      displayResult("Success");
    } else {
      // Script execution failed
      println("Script execution failed.");
      displayResult("Error");
    }
  } catch (Exception e) {
    e.printStackTrace();
    println("An exception occurred: " + e.getMessage());
    displayResult("Error");
  }
}

void displayResult(String result) {
  background(0);
  textAlign(CENTER, CENTER);
  textSize(80);
  fill(255);
  text(result, width / 2, height / 2);
}

class Keyboard {
  String[] keys = {
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
    "!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
    "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
    "a", "s", "d", "f", "g", "h", "j", "k", "l",
    "z", "x", "c", "v", "b", "n", "m", "bsp"
  };
  float keySize = 38;
  float xButtonSize = 80; // Separate size for "X" button
  float keySpacingX = 15; // Adjusted spacing for keys
  float keySpacingY = 10;
  float keyboardX = width / 2 - ((keySize + keySpacingX) * 10 - keySpacingX) / 2.2;
  float keyboardY = height / 5;
  boolean isBspaceClicked = false; // Track "bspace" button click

  void display() {
    textAlign(CENTER, CENTER);
    textSize(30); // Keyboard text size
    fill(0);
    for (int i = 0; i < keys.length; i++) {
      float x = keyboardX + (i % 10) * (keySize + keySpacingX);
      float y = keyboardY + floor(i / 10) * (keySize + keySpacingY);
      stroke(50, 205, 50);
      strokeWeight(1.5);
      fill(128, 128, 128);
      if (keys[i].equals("bsp")) {
        rect(x + 26, y, xButtonSize, keySize, 5); // Different size for "X" button
      } else {
        rect(x+3.5, y, keySize, keySize, 5);
      }
      fill(0);
      text(keys[i], x + (keys[i].equals("bsp") ? xButtonSize : keySize) / 9, y + keySize / 90);
    }
  }

  void handleMouseClick() {
    for (int i = 0; i < keys.length; i++) {
      float x = keyboardX + (i % 10) * (keySize + keySpacingX);
      float y = keyboardY + floor(i / 10) * (keySize + keySpacingY);
      if (mouseX >= x && mouseX <= x + (keys[i].equals("bsp") ? xButtonSize : keySize) && mouseY >= y && mouseY <= y + keySize) {
        if (keys[i].equals("bsp")) {
          if (!userIdField.value.isEmpty()) {
            userIdField.value = userIdField.value.substring(0, userIdField.value.length() - 1);
          }
          isBspaceClicked = true; // Set the flag to indicate "bspace" button is clicked
        } else {
          userIdField.value += keys[i];
        }
      }
    }
    if (isBspaceClicked) {
      isBspaceClicked = false; // Reset the flag
      saveDataToFile(); // Save data to file after removing a character
    }
  }
}

void logOut() {
  // Display a confirmation dialog
  int dialogResponse = JOptionPane.showOptionDialog(null, "Are you sure you want to log out?", "Confirmation", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE, null, null, null);

  if (dialogResponse == JOptionPane.YES_OPTION) {
    // Reset UI state and variables for logout
    isFirstPage = true;
    isReadingStarted = false;
    isReadingPaused = false;
    displaySensorData = false;
    userIdField.value = "";
    output.flush();
    output.close();

    println("Logged out successfully.");

    exit(); // Exit the program
  }
}

String getTimeString() {
  SimpleDateFormat dateFormat = new SimpleDateFormat("hh:mm:ss a");
  Date date = new Date();
  return dateFormat.format(date);
}

void startTimer() {
  timerStarted = true;
  previousTime = millis();
}

void stopTimer() {
  timerStarted = false;
}

void updateTimer() {
  if (timerStarted) {
    int currentTime = millis();
    elapsedTime += currentTime - previousTime;
    previousTime = currentTime;
  }
}

  String getElapsedTime() {
  int seconds = elapsedTime / 1000;
  int minutes = seconds / 60;
  int hours = minutes / 60;
  seconds %= 60;
  minutes %= 60;

  return nf(hours, 2) + ":" + nf(minutes, 2) + ":" + nf(seconds, 2);
}
