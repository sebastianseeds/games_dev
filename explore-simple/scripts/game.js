// ---------------------------------------
// CONSTANTS AND VARIABLES
// ---------------------------------------

//Globals
const DEBUG = true; // Set to true to enable debugging

const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");
const gameContainer = document.getElementById("game-container"); // Ensure gameContainer is properly defined

const redSquare = document.createElement("div"); // Red square for "F" functionality
redSquare.style.width = "20px";
redSquare.style.height = "20px";
redSquare.style.backgroundColor = "red";
redSquare.style.position = "absolute";
redSquare.style.display = "none"; // Hidden by default
gameContainer.appendChild(redSquare);

let isGameOver = false;

// Add Game Over screen
const returnToMenuButton = document.getElementById("return-to-main-menu"); // Get the button element
if (returnToMenuButton) {
    returnToMenuButton.style.display = "block";
    returnToMenuButton.style.visibility = "visible";
    returnToMenuButton.style.zIndex = "1000";
    returnToMenuButton.style.backgroundColor = "red"; // Highlight for debugging
}

// Handle Return from Settings Menu
const returnFromSettingsButton = document.getElementById("return-from-settings");
if (returnFromSettingsButton) {
    returnFromSettingsButton.onclick = () => {
        console.log("Returning to Main Menu from Settings...");
        showMainMenu(); // Use existing logic to show the Main Menu
    };
}

// Sounds
const collectSound = document.getElementById("collect-sound"); // Reference the audio element in index
const doorSound = document.getElementById("door-sound");
const damageSound = document.getElementById("damage-sound");

// Sprite
const FRAME_WIDTH = 66; // Sprite frame width
const FRAME_HEIGHT = 100; // Sprite frame height
const COLUMNS = 4; // Frames per row
const ROWS = 4; // Total rows
const ANIMATION_SPEED = 100; // Milliseconds per frame
const speed = 5; // Movement speed

let currentFrame = 0; // Current animation frame
let currentRow = 0; // 0: Down, 1: Up, 2: Left, 3: Right
let lastUpdateTime = 0; // Time tracking for animations
let playerX = 100; // Player's starting X position
let playerY = 100; // Player's starting Y position
let isMoving = false;
let playerCanMove = true; // Controls whether the player can move

// Hitbox configuration
const HITBOX_OFFSET_X = 14; // Shift hitbox left/right from the sprite center
const HITBOX_OFFSET_Y = 20;  // Shift hitbox up/down from the sprite center
const HITBOX_WIDTH = 40;    // Fixed hitbox width
const HITBOX_HEIGHT = 68;   // Fixed hitbox height

// Game container
const gameWidth = 600; // Game container width
const gameHeight = 600; // Game container height
const redDotCount = 5; // Number of red dots
const minDistance = 30; // Minimum distance between dots

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

// Weapon Configurations
const weapons = {
    fist: {
        width_v: 20,
	height_v: 20,
	width_h: 20,
        height_h: 20,
	offsetX_left: -10,
	offsetX_right: -10,
	offsetX_up: 25,
	offsetX_down: 25,
	offsetY_left: 50,
	offsetY_right: 50,
	offsetY_up: 0,
	offsetY_down: -5,
	damage: 1,
    },
    knife: {
        width_v: 20,
	height_v: 40,
	width_h: 40,
        height_h: 20,
	offsetX_left: -10,
	offsetX_right: -10,
	offsetX_up: 25,
	offsetX_down: 25,
	offsetY_left: 50,
	offsetY_right: 50,
	offsetY_up: 20,
	offsetY_down: -5,
	damage: 2,
    },
    broadsword: {
	width_v: 30,
	height_v: 60,
	width_h: 60,
	height_h: 30,
	offsetX_left: -10,
	offsetX_right: -10,
	offsetX_up: 20,
	offsetX_down: 20,
	offsetY_left: 50,
	offsetY_right: 50,
	offsetY_up: 40,
	offsetY_down: -5,
	damage: 4,
    },
    spear: {
	width_v: 10,
	height_v: 90,
	width_h: 90,
	height_h: 10,
	offsetX_left: -10,
	offsetX_right: -10,
	offsetX_up: 30,
	offsetX_down: 30,
	offsetY_left: 50,
	offsetY_right: 50,
	offsetY_up: 70,
	offsetY_down: -5,
	damage: 3,
    },
    whip: {
	width_v: 5,
	height_v: 120,
	width_h: 120,
	height_h: 5,
	offsetX_left: -10,
	offsetX_right: -10,
	offsetX_up: 30,
	offsetX_down: 30,
	offsetY_left: 50,
	offsetY_right: 50,
	offsetY_up: 100,
	offsetY_down: -5,
	damage: 2,
    },
};

// Red Box (Weapon) Properties
let currentWeapon = weapons.spear; // Default weapon

// Different kinds of enemies
const dotTypes = [
    { color: "red", hp: 2, size: 20 },    // Smallest & weakest
    { color: "blue", hp: 3, size: 22 },
    { color: "green", hp: 4, size: 24 },
    { color: "yellow", hp: 5, size: 26 },
    { color: "purple", hp: 6, size: 28 }, // Largest & strongest
];


document.addEventListener("click", (event) => {
    console.log("Clicked element:", event.target);
});

// ---------------------------------------
// INITIALIZATION
// ---------------------------------------
spriteSheet.onload = () => {
    initializeGame();
    gameLoop(0);
};

function initializeGame() {
    showMainMenu();
    attachEventListeners();
}

// Attach event listeners for buttons and keyboard
function attachEventListeners() {
    // Main Menu Buttons
    newGameButton.addEventListener("click", startNewGame);
    settingsButton.addEventListener("click", showSettingsMenu);

    // Settings Menu
    returnFromSettingsButton.addEventListener("click", showMainMenu);

    // Game Over Screen
    returnToMenuButton.addEventListener("click", resetGame);

    // Keyboard Controls
    document.addEventListener("keydown", handleKeyDown);
    document.addEventListener("keyup", handleKeyUp);
}

// ---------------------------------------
// MENU FUNCTIONS
// ---------------------------------------
const mainMenu = document.getElementById("main-menu"); // Main menu div
const settingsMenu = document.getElementById("settings-menu"); // Settings menu div
const gameOverScreen = document.getElementById("game-over-screen"); // Game Over screen div
const newGameButton = document.getElementById("new-game"); // Button: New Game
const continueGameButton = document.getElementById("continue-game"); // Button: Continue
const settingsButton = document.getElementById("settings"); // Button: Settings

// Show the main menu
function showMainMenu() {
    console.log("Showing main menu...");
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

// ---------------------------------------
// HANDLE GAME OVER
// ---------------------------------------
function resetGame() {
    console.log("Resetting game...");

    // Reset game state
    isGameRunning = false;
    isGameOver = false;
    redDotCollected = 0;

    // Reset player position
    resetPlayerPosition();

    // Clear game elements
    redDots.forEach(dot => dot.remove());
    redDots = [];

    // Remove the door if it exists
    if (door) {
        door.remove();
        door = null;
    }

    // Reset UI elements
    //updateRedDotCounter();
    redDotCounter.style.display = "none";
    gameContainer.style.display = "none";
    gameOverScreen.style.display = "none";
    mainMenu.style.display = "flex";

    // Log game reset complete
    console.log("Game reset complete. Returning to main menu.");
}


function resetPlayerPosition() {
    playerX = gameWidth / 2 - FRAME_WIDTH / 2;
    playerY = gameHeight / 2 - FRAME_HEIGHT / 2;
}

function gameOver() {
    isGameRunning = false; // Stop the game loop
    isGameOver = true; // Set game state to "over"

    // Show the Game Over screen
    gameOverScreen.style.display = "block";
    gameContainer.style.display = "none";

    console.log("Game Over triggered. Waiting for reset...");

    // Handle Return to Main Menu button
    const returnToMenuButton = document.getElementById("return-to-main-menu");
    if (returnToMenuButton) {
        returnToMenuButton.onclick = () => {
            console.log("Return to Main Menu button clicked!");
            resetGame(); // Reset the game
        };
    } else {
        console.error("Return to Main Menu button not found!");
    }
}


// ---------------------------------------
// GAME LOOP
// ---------------------------------------
function gameLoop(timestamp) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw the hitbox only in debug mode
    if (DEBUG) {
        ctx.strokeStyle = "red"; // Red outline for hitbox
        ctx.lineWidth = 1; // Optional: Make the outline thinner
        ctx.strokeRect(
            playerX + HITBOX_OFFSET_X,
            playerY + HITBOX_OFFSET_Y,
            HITBOX_WIDTH,
            HITBOX_HEIGHT
        );
    }

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
    }

    if (DEBUG) {
	ctx.strokeStyle = "red"; // Red outline for weapon hitbox
	ctx.lineWidth = 1;
	ctx.strokeRect(
            parseFloat(redSquare.style.left) || 0,
            parseFloat(redSquare.style.top) || 0,
            parseFloat(redSquare.style.width) || currentWeapon.width_v,
            parseFloat(redSquare.style.height) || currentWeapon.height_v
	);
    }
}



// ---------------------------------------
// HANDLE ATTACKING
// ---------------------------------------
function setWeapon(weaponName) {
    if (weapons[weaponName]) {
        currentWeapon = weapons[weaponName];
        console.log(`Weapon set to: ${weaponName}`, currentWeapon);
    } else {
        console.error(`Weapon "${weaponName}" not found!`);
    }
}

function triggerRedSquare() {
    if (isGameOver || !playerCanMove) return;

    playerCanMove = false; // Disable movement temporarily
    let squareX = playerX;
    let squareY = playerY;

    // Determine attack orientation
    let isVertical = currentRow === 0 || currentRow === 1;
    let weaponWidth = isVertical ? currentWeapon.width_v : currentWeapon.width_h;
    let weaponHeight = isVertical ? currentWeapon.height_v : currentWeapon.height_h;
    let weaponDamage = currentWeapon.damage;

    // Get the correct offset values based on direction
    let offsetX, offsetY;
    if (currentRow === 0) { // Facing down
        offsetX = currentWeapon.offsetX_down;
        offsetY = currentWeapon.offsetY_down;
        squareX += offsetX;
        squareY += FRAME_HEIGHT + offsetY;
    } else if (currentRow === 1) { // Facing up
        offsetX = currentWeapon.offsetX_up;
        offsetY = currentWeapon.offsetY_up;
        squareX += offsetX;
        squareY -= offsetY;
    } else if (currentRow === 2) { // Facing left
        offsetX = currentWeapon.offsetX_left;
        offsetY = currentWeapon.offsetY_left;
        squareX -= offsetX + weaponWidth;
        squareY += offsetY;
    } else if (currentRow === 3) { // Facing right
        offsetX = currentWeapon.offsetX_right;
        offsetY = currentWeapon.offsetY_right;
        squareX += FRAME_WIDTH + offsetX;
        squareY += offsetY;
    }

    // Apply size and position to the red square
    redSquare.style.left = `${squareX}px`;
    redSquare.style.top = `${squareY}px`;
    redSquare.style.width = `${weaponWidth}px`;
    redSquare.style.height = `${weaponHeight}px`;
    redSquare.style.display = "block";

    // Check for collision with red dots
    redDots = redDots.filter(dot => {
        if (isCollidingWithSquare(dot, squareX, squareY, weaponWidth, weaponHeight)) {
            let dotHP = parseInt(dot.dataset.hp, 10); // Get HP value
            dotHP -= weaponDamage; // Reduce HP by 1
            dot.dataset.hp = dotHP; // Update stored HP

            if (dotHP <= 0) {
                // Play destruction sound
                try {
                    collectSound.currentTime = 0;
                    collectSound.play();
                } catch (error) {
                    console.error("Error playing collect sound:", error);
                }

                // Remove the red dot
                dot.remove();
                redDotCollected++;
                updateRedDotCounter();
                return false; // Remove from array
            } else {
                // Play damage sound only if the red dot still has HP left
                try {
                    damageSound.currentTime = 0;
                    damageSound.play();
                } catch (error) {
                    console.error("Error playing damage sound:", error);
                }
            }

            return true; // Keep dot if it still has HP
        }
        return true;
    });

    // Hide the red square and re-enable movement after a short cooldown
    setTimeout(() => {
        redSquare.style.display = "none";
        playerCanMove = true;
    }, 200);
}




function isCollidingWithSquare(dot, squareX, squareY, weaponWidth, weaponHeight) {
    const dotX = parseFloat(dot.style.left);
    const dotY = parseFloat(dot.style.top);
    const dotSize = parseFloat(dot.dataset.size) || 20; // Default to 20 if missing

    return (
        squareX < dotX + dotSize &&
        squareX + weaponWidth > dotX &&
        squareY < dotY + dotSize &&
        squareY + weaponHeight > dotY
    );
}



// ---------------------------------------
// DOT AND DOOR INTERACTIONS
// ---------------------------------------
function createRedDots() {
    redDots.forEach(dot => dot.remove()); // Remove existing dots
    redDots = []; // Clear array

    dotTypes.forEach(dotType => {
        const redDot = document.createElement("div");
        redDot.classList.add("red-dot");

        // Assign unique color, HP, and size
        redDot.style.backgroundColor = dotType.color;
        redDot.style.width = `${dotType.size}px`;
        redDot.style.height = `${dotType.size}px`;
        redDot.dataset.hp = dotType.hp.toString(); // Store HP
        redDot.dataset.size = dotType.size.toString(); // Store size

        // Randomize position
        let position;
        let attempts = 0;
        do {
            position = {
                x: Math.random() * (gameWidth - dotType.size),
                y: Math.random() * (gameHeight - dotType.size),
            };
            attempts++;
            if (attempts > 50) {
                console.warn(`Failed to place ${dotType.color} dot after 50 tries, skipping.`);
                break;
            }
        } while (!isPositionValid(position));

        // Apply position
        if (isPositionValid(position)) {
            redDot.style.left = `${position.x}px`;
            redDot.style.top = `${position.y}px`;
            gameContainer.appendChild(redDot);
            redDots.push(redDot);
        }
    });
}





function checkInteractions() {
    // Check collision with red dots
    redDots = redDots.filter(dot => {
        if (isColliding(dot)) {
            gameOver(); // End the game if the player collides with a red dot
            return false; // Remove the dot from the array
        }
        return true; // Keep the dot if no collision
    });

    // If all red dots are collected and no door exists, create a door
    if (redDots.length === 0 && !door) {
        createDoor();
    }

    // Check collision with the door
    if (door && isColliding(door)) {
        nextStage(); // Move to the next stage if the player collides with the door
    }
}

function createDoor() {
    // Remove existing door if present
    if (door) door.remove();

    // Create the door element
    door = document.createElement("div");
    door.id = "door";

    // Set the door's size dynamically (40x40 by default)
    door.style.width = "40px";
    door.style.height = "40px";

    // Randomize placement on one side of the game area
    door.style.left = `${gameWidth / 2 - 20}px`; // Center horizontally
    door.style.top = `${gameHeight / 2 - 20}px`; // Center vertically

    // Add the door to the game container
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
function isColliding(object) {
    // Get object's position and dimensions dynamically
    const objectX = parseFloat(object.style.left); // Object's X position
    const objectY = parseFloat(object.style.top); // Object's Y position
    const objectWidth = parseFloat(object.style.width) || 0; // Object's width
    const objectHeight = parseFloat(object.style.height) || 0; // Object's height

    // Check for collision with the player's hitbox
    return (
        playerX + HITBOX_OFFSET_X < objectX + objectWidth && // Player's right edge > Object's left edge
        playerX + HITBOX_OFFSET_X + HITBOX_WIDTH > objectX && // Player's left edge < Object's right edge
        playerY + HITBOX_OFFSET_Y < objectY + objectHeight && // Player's bottom edge > Object's top edge
        playerY + HITBOX_OFFSET_Y + HITBOX_HEIGHT > objectY   // Player's top edge < Object's bottom edge
    );
}


function isPositionValid(position) {
    const playerStartX = gameWidth / 2 - FRAME_WIDTH / 2;
    const playerStartY = gameHeight / 2 - FRAME_HEIGHT / 2;

    // Ensure the dot does not spawn inside the player
    const buffer = 30; // Buffer distance to prevent overlap
    const collidesWithPlayer =
        position.x + 20 > playerStartX - buffer &&
        position.x < playerStartX + FRAME_WIDTH + buffer &&
        position.y + 20 > playerStartY - buffer &&
        position.y < playerStartY + FRAME_HEIGHT + buffer;

    if (collidesWithPlayer) return false;

    // Ensure dots do not overlap with each other
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

    // Trigger red square when "F" is pressed
    if (event.key === "f") {
        triggerRedSquare();
    }
}

function handleKeyUp(event) {
    if (keys[event.key] !== undefined) keys[event.key] = false;
}

function updatePlayerPosition() {
    if (DEBUG) console.log(`Current speed: ${speed}`); // Debugging line
    if (!playerCanMove) return; // Prevent movement during cooldown

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
