#include <AFMotor.h>
#include <SoftwareSerial.h>

// Inicialización de los pines del módulo Bluetooth
SoftwareSerial BTSerial(2, 3); 

// Inicialización de los motores
AF_DCMotor motor1(1); // Motor 1
AF_DCMotor motor2(2); // Motor 2 
AF_DCMotor motor3(3); // Motor 3 
AF_DCMotor motor4(4); // Motor 4 

// Pins para el sensor ultrasonido
const int trigPin = A0;
const int echoPin = A1;
const int obstacleDistance = 20; 

boolean isMoving = false;
boolean autoModeEnabled = false;

void setup() {
  Serial.begin(9600); 
  BTSerial.begin(9600); 

  // Configuración inicial de los motores
  motor1.setSpeed(255); 
  motor2.setSpeed(255); 
  motor3.setSpeed(255); 
  motor4.setSpeed(255); 

  // Inicialización de pines para el sensor ultrasonido
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
}

void loop() {
  // Verificación constante del sensor ultrasonido
  long duration, distance;

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;

  if (distance <= obstacleDistance && isMoving) {
    moveStop(); // Detener el movimiento si se detecta un obstáculo cercano
    Serial.println("Obstáculo detectado. Deteniendo el carro...");
  }

  // Control por Bluetooth
  if (BTSerial.available()) {
    char receivedChar = BTSerial.read();
    Serial.println(receivedChar);

    switch (receivedChar) {
      case '1':
        Serial.println("Botón de encendido presionado");
        break;
      case '0':
        Serial.println("Botón de apagado presionado");
        break;
      case 'F':
        Serial.println("Movimiento hacia adelante");
        moveForward();
        break;
      case 'B':
        Serial.println("Movimiento hacia atrás");
        moveBackward();
        break;
      case 'L':
        Serial.println("Girar a la izquierda");
        turnLeft();
        break;
      case 'R':
        Serial.println("Girar a la derecha");
        turnRight();
        break;
      case 'A':
        Serial.println("Modo automático activado");
        autoMode();
        break;
      case 'P':
        Serial.println("Pausar movimiento");
        pauseMovement();
        break;
      default:
        Serial.println("Comando desconocido");
        break;
    }
  }

  // Lógica para el modo automático con sensor de ultrasonido
  if (autoModeEnabled) {
    if (distance > obstacleDistance) {
      // Continuar moviéndose hacia adelante si no hay obstáculos
      moveForward();
    } else {
      Serial.println("Obstáculo detectado en modo automático. Buscando otro camino...");

      // Lógica para buscar otro camino (por ejemplo, girar a la derecha)
      turnRight();
      delay(1000); // Ajusta el tiempo necesario para que el carro gire
      moveForward(); // Continuar moviéndose hacia adelante
    }
  }

  // Otros comandos o lógica del programa
}

void moveForward() {
  Serial.println("Moviendo hacia adelante");
  motor1.run(FORWARD);
  motor2.run(FORWARD);
  motor3.run(FORWARD);
  motor4.run(FORWARD);
  isMoving = true;
}

void moveBackward() {
  Serial.println("Moviendo hacia atrás");
  motor1.run(BACKWARD);
  motor2.run(BACKWARD);
  motor3.run(BACKWARD);
  motor4.run(BACKWARD);
  isMoving = true;
}

void turnLeft() {
  Serial.println("Girando a la izquierda");
  motor1.run(BACKWARD);
  motor2.run(BACKWARD);
  motor3.run(FORWARD);
  motor4.run(FORWARD);
  delay(500);
  moveStop();
}

void turnRight() {
  Serial.println("Girando a la derecha");
  motor1.run(FORWARD);
  motor2.run(FORWARD);
  motor3.run(BACKWARD);
  motor4.run(BACKWARD);
  delay(500);
  moveStop();
}

void moveStop() {
  Serial.println("Deteniendo todos los motores");
  motor1.run(RELEASE);
  motor2.run(RELEASE);
  motor3.run(RELEASE);
  motor4.run(RELEASE);
  isMoving = false; // Actualiza el estado del movimiento
}

void autoMode() {
  autoModeEnabled = true; // Activa el modo automático
  moveForward(); // Inicia el movimiento hacia adelante inmediatamente
}

void pauseMovement() {
  moveStop();
  autoModeEnabled = false; // Desactiva el modo automático
}
