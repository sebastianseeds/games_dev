// ---------------------------------------
// CONSTANTS AND VARIABLES
// ---------------------------------------
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");
const gameContainer = document.getElementById("game-container"); // Ensure gameContainer is properly defined

const FRAME_WIDTH = 66; // Sprite frame width
const FRAME_HEIGHT = 100; // Sprite frame height
const COLUMNS = 4; // Frames per row
const ROWS = 4; // Total rows
const ANIMATION_SPEED = 100; // Milliseconds per frame
const speed = 5; // Movement speed

const gameWidth = 600; // Game container width
const gameHeight = 600; // Game container height
const redDotCount = 5; // Number of red dots
const minDistance = 30; // Minimum distance between dots

let currentFrame = 0; // Current animation frame
let currentRow = 0; // 0: Down, 1: Up, 2: Left, 3: Right
let lastUpdateTime = 0; // Time tracking for animations
let playerX = 100; // Player's starting X position
let playerY = 100; // Player's starting Y position
let isMoving = false;

const keys = { ArrowLeft: false, ArrowRight: false, ArrowUp: false, ArrowDown: false };
let redDotCollected = 0;
let redDots = [];
let door;

let isGameRunning = false;

// Load sprite sheet
const spriteSheet = new Image();
spriteSheet.src = "images/ex_player_ss_v2.png";

// UI elements
const redDotCounter = document.getElementById("red-dot-counter");

// ---------------------------------------
// INITIALIZATION
// ---------------------------------------
spriteSheet.onload = () => {
    initializeGame();
    gameLoop(0);
};

function initializeGame() {
    showMainMenu();
    document.addEventListener("keydown", handleKeyDown);
    document.addEventListener("keyup", handleKeyUp);
}

// ---------------------------------------
// MENU FUNCTIONS
// ---------------------------------------
const mainMenu = document.getElementById("main-menu"); // Main menu div
const settingsMenu = document.getElementById("settings-menu"); // Settings menu div
const newGameButton = document.getElementById("new-game"); // Button: New Game
const continueGameButton = document.getElementById("continue-game"); // Button: Continue
const settingsButton = document.getElementById("settings"); // Button: Settings

// Show the main menu
function showMainMenu() {
    mainMenu.style.display = "flex";
    settingsMenu.style.display = "none";
    gameContainer.style.display = "none";
    toggleRedDotCounter(false);
}

// Start a new game
function startNewGame() {
    mainMenu.style.display = "none";
    gameContainer.style.display = "block";

    // Keep player position consistent
    playerX = gameWidth / 2 - FRAME_WIDTH / 2;
    playerY = gameHeight / 2 - FRAME_HEIGHT / 2;

    // Do NOT reset the red dot counter
    updateRedDotCounter();

    // Generate new red dots for the next stage
    createRedDots();

    if (!isGameRunning) {
        isGameRunning = true; // Set the flag
        requestAnimationFrame(gameLoop); // Start the game loop
    }}

// Show settings menu
function showSettingsMenu() {
    mainMenu.style.display = "none";
    settingsMenu.style.display = "flex";
}

// Event listeners for buttons
newGameButton.addEventListener("click", startNewGame);
settingsButton.addEventListener("click", showSettingsMenu);


// ---------------------------------------
// GAME LOOP
// ---------------------------------------
function gameLoop(timestamp) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    updatePlayerPosition();
    checkInteractions();

    if (isMoving && timestamp - lastUpdateTime > ANIMATION_SPEED) {
        currentFrame = (currentFrame + 1) % COLUMNS;
        lastUpdateTime = timestamp;
    }

    // Draw player sprite
    ctx.drawImage(
        spriteSheet,
        currentFrame * FRAME_WIDTH,
        currentRow * FRAME_HEIGHT,
        FRAME_WIDTH,
        FRAME_HEIGHT,
        playerX,
        playerY,
        FRAME_WIDTH,
        FRAME_HEIGHT
    );

    if (isGameRunning) {
        requestAnimationFrame(gameLoop);
    }}

// ---------------------------------------
// CONSTANTS AND VARIABLES
// ---------------------------------------
const collectSound = document.getElementById("collect-sound"); // Reference the audio element
const doorSound = document.getElementById("door-sound"); // Reference the audio element


// ---------------------------------------
// DOT AND DOOR INTERACTIONS
// ---------------------------------------
function createRedDots() {
    redDots.forEach(dot => dot.remove()); // Remove existing dots
    redDots = []; // Clear array

    for (let i = 0; i < redDotCount; i++) {
        const redDot = document.createElement("div");
        redDot.classList.add("red-dot");

        let position;
        do {
            position = {
                x: Math.random() * (gameWidth - 20), // Ensure dots fit within bounds
                y: Math.random() * (gameHeight - 20),
            };
        } while (!isPositionValid(position)); // Check spacing between dots

        redDot.style.left = `${position.x}px`;
        redDot.style.top = `${position.y}px`;
        gameContainer.appendChild(redDot);
        redDots.push(redDot); // Store the dot in the array
    }
}

function checkInteractions() {
    redDots = redDots.filter(dot => {
        if (isColliding(dot)) {
            dot.remove();
            redDotCollected++;

            // Play red dot collection sound
            try {
                const collectSound = document.getElementById("collect-sound");
                collectSound.currentTime = 0;
                collectSound.play();
            } catch (error) {
                console.error("Error playing collect sound:", error);
            }

            updateRedDotCounter();
            return false;
        }
        return true;
    });

    if (redDots.length === 0 && !door) {
        createDoor();
    }

    if (door && isColliding(door)) {
        nextStage();
    }
}

function createDoor() {
    door = document.createElement("div");
    door.id = "door";
    door.style.left = `${gameWidth / 2 - 20}px`;
    door.style.top = `${gameHeight / 2 - 20}px`;
    gameContainer.appendChild(door);
}

function nextStage() {
    if (door) {
        door.remove();
        door = null;

        // Play the door sound
        try {
            const doorSound = document.getElementById("door-sound");
            doorSound.currentTime = 0; // Reset the sound
            doorSound.play(); // Play the sound
        } catch (error) {
            console.error("Error playing door sound:", error); // Log errors
        }
    }

    startNewGame(); // Restart with new positions for red dots
}
// ---------------------------------------
// COLLISION AND VALIDATION
// ---------------------------------------
function isColliding(dot) {
    const dotX = parseFloat(dot.style.left); // Get X position of the dot
    const dotY = parseFloat(dot.style.top); // Get Y position of the dot

    return (
        playerX < dotX + 20 && // Dot width is 20px
        playerX + FRAME_WIDTH > dotX &&
        playerY < dotY + 20 && // Dot height is 20px
        playerY + FRAME_HEIGHT > dotY
    );
}

function isPositionValid(position) {
    return redDots.every(dot => {
        const dotX = parseFloat(dot.style.left);
        const dotY = parseFloat(dot.style.top);
        const distance = Math.sqrt(
            (position.x - dotX) ** 2 + (position.y - dotY) ** 2
        );
        return distance >= minDistance;
    });
}

// ---------------------------------------
// PLAYER MOVEMENT
// ---------------------------------------
function handleKeyDown(event) {
    if (keys[event.key] !== undefined) keys[event.key] = true;
}

function handleKeyUp(event) {
    if (keys[event.key] !== undefined) keys[event.key] = false;
}

function updatePlayerPosition() {
    console.log(`Current speed: ${speed}`); // Debugging line

    isMoving = false;

    if (keys.ArrowLeft && playerX > 0) {
        playerX -= speed;
        currentRow = 2; // Left
        isMoving = true;
    } else if (keys.ArrowRight && playerX < gameWidth - FRAME_WIDTH) {
        playerX += speed;
        currentRow = 3; // Right
        isMoving = true;
    } else if (keys.ArrowUp && playerY > 0) {
        playerY -= speed;
        currentRow = 1; // Up
        isMoving = true;
    } else if (keys.ArrowDown && playerY < gameHeight - FRAME_HEIGHT) {
        playerY += speed;
        currentRow = 0; // Down
        isMoving = true;
    }
}

// ---------------------------------------
// COUNTER DISPLAY
// ---------------------------------------
function updateRedDotCounter() {
    redDotCounter.textContent = `Red Dots Collected: ${redDotCollected}`;
    redDotCounter.style.display = "block";
}

function toggleRedDotCounter(visible) {
    redDotCounter.style.display = visible ? "block" : "none";
}
