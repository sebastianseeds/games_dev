// ---------------------------------------
// CONSTANTS AND VARIABLES
// ---------------------------------------
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");

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
let saveStates = JSON.parse(localStorage.getItem("saveStates")) || {};
let currentSaveName = null;

const redDots = [];
const whiteDots = Array.from(document.querySelectorAll(".interactive-dot"));

const spriteSheet = new Image();
spriteSheet.src = "images/ex_player_ss_v2.png";

// Menu and UI elements
const mainMenu = document.getElementById("main-menu");
const settingsMenu = document.getElementById("settings-menu");
const gameContainer = document.getElementById("game-container");
const pauseMenu = document.getElementById("pause-menu");
const saveSelectMenu = document.getElementById("save-select-menu");
const redDotCounter = document.getElementById("red-dot-counter");
const dialogueBox = document.getElementById("dialogue-box");
const dialogueText = document.getElementById("dialogue-text");
const newGameButton = document.getElementById("new-game");
const continueGameButton = document.getElementById("continue-game");
const settingsButton = document.getElementById("settings");

//DEBUG
console.log("JavaScript loaded successfully!");

// ---------------------------------------
// MENU FUNCTIONS
// ---------------------------------------
function toggleMenu(menu, show) {
    menu.style.display = show ? "flex" : "none";
}

function showMainMenu() {
    toggleMenu(mainMenu, true);
    toggleMenu(settingsMenu, false);
    toggleMenu(gameContainer, false);
    toggleMenu(pauseMenu, false);
    toggleRedDotCounter(false);
}

function startNewGame() {
    toggleMenu(mainMenu, false);
    toggleMenu(gameContainer, true);
    playerX = gameWidth / 2 - FRAME_WIDTH / 2;




    playerY = gameHeight / 2 - FRAME_HEIGHT / 2;
    updatePlayerPosition();
    createRedDots();
    createDoor();
    toggleRedDotCounter(true);
}

function togglePauseMenu() {
    console.log("Toggling Pause Menu...");
    if (pauseMenu.style.display === "none") {
        toggleMenu(pauseMenu, true);
    } else {
        toggleMenu(pauseMenu, false);
    }
}

function showSaveSelectMenu() {
    console.log("Save Select Menu clicked!");
    toggleMenu(saveSelectMenu, true);
    toggleMenu(mainMenu, false);
}

function showSettingsMenu() {
    console.log("Settings menu clicked!");
    toggleMenu(settingsMenu, true);
    toggleMenu(mainMenu, false);
}

// Event listeners for menu buttons
newGameButton.addEventListener("click", () => {
    console.log("New Game button clicked!");
    startNewGame();
});
document.addEventListener("keydown", (event) => {
    console.log(`Key pressed: ${event.key}`); // Debugging log
    if (event.key === "Escape" && gameContainer.style.display === "block") {
        console.log("Escape key pressed!");
        togglePauseMenu();
    }
});
continueGameButton.addEventListener("click", showSaveSelectMenu);
settingsButton.addEventListener("click", showSettingsMenu);

// ---------------------------------------
// SPRITE AND GAME LOOP
// ---------------------------------------
function gameLoop(timestamp) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Update player position
    updatePlayerPosition();
    checkInteractions();

    // Handle animation updates only when moving
    if (isMoving && timestamp - lastUpdateTime > ANIMATION_SPEED) {
        currentFrame = (currentFrame + 1) % COLUMNS;
        lastUpdateTime = timestamp;
    }

    // Draw player sprite
    ctx.drawImage(
        spriteSheet,
        currentFrame * FRAME_WIDTH, // Source X
        currentRow * FRAME_HEIGHT, // Source Y
        FRAME_WIDTH, FRAME_HEIGHT, // Source dimensions
        playerX, playerY,          // Destination X, Y
        FRAME_WIDTH, FRAME_HEIGHT  // Destination dimensions
    );

    requestAnimationFrame(gameLoop);
}


function updatePlayerPosition() {
    isMoving = false; // Assume the player is not moving

    if (keys.ArrowLeft) {
        playerX -= speed;
        currentRow = 2; // Left
        isMoving = true;
    } else if (keys.ArrowRight) {
        playerX += speed;
        currentRow = 3; // Right
        isMoving = true;
    } else if (keys.ArrowUp) {
        playerY -= speed;
        currentRow = 1; // Up
        isMoving = true;
    } else if (keys.ArrowDown) {
        playerY += speed;
        currentRow = 0; // Down
        isMoving = true;
    }

    
    // Reset to the standing frame if no movement keys are pressed
    if (!isMoving) {
        if (currentRow === 3) {
            currentFrame = 1; // Use column 2 for the "standing still" frame in row 4 (walking right)
        } else {
            currentFrame = 0; // Use column 1 for other rows
        }
    }
}

// ---------------------------------------
// DOT AND DOOR INTERACTIONS
// ---------------------------------------
function createRedDots() {
    redDots.forEach(dot => dot.remove());
    redDots.length = 0;

    for (let i = 0; i < redDotCount; i++) {
        const redDot = document.createElement("div");
        redDot.classList.add("red-dot");
        let position;

        do {
            position = {
                x: Math.random() * (gameWidth - 20),
                y: Math.random() * (gameHeight - 20)
            };
        } while (!isPositionValid(position));

        redDot.style.left = `${position.x}px`;
        redDot.style.top = `${position.y}px`;
        gameContainer.appendChild(redDot);
        redDots.push(redDot);
    }
}

function toggleRedDotCounter(visible) {
    const counterElement = document.getElementById("red-dot-counter");
    if (counterElement) {
        counterElement.style.display = visible ? "block" : "none";
    }
}

function updateRedDotCounter() {
    const counterElement = document.getElementById("red-dot-counter");
    if (counterElement) {
        counterElement.textContent = `Red Dots Collected: ${redDotCollected}`;
    }
}

function createDoor() {
    const door = document.createElement("div");
    door.id = "door";
    door.style.width = "40px";
    door.style.height = "40px";
    door.style.backgroundColor = "blue";
    door.style.position = "absolute";

    // Place door on random side
    const side = Math.floor(Math.random() * 4);
    if (side === 0) door.style.top = "0px";
    if (side === 1) door.style.left = `${gameWidth - 40}px`;
    if (side === 2) door.style.top = `${gameHeight - 40}px`;
    if (side === 3) door.style.left = "0px";

    gameContainer.appendChild(door);
}

function enterDoor() {
    createRedDots();
    createDoor();
    playerX = gameWidth / 2 - FRAME_WIDTH / 2;
    playerY = gameHeight / 2 - FRAME_HEIGHT / 2;
    updatePlayerPosition();
}

function isPositionValid(position) {
    return whiteDots.every(whiteDot => {
        const rect = whiteDot.getBoundingClientRect();
        const distance = Math.sqrt(Math.pow(position.x - rect.left, 2) + Math.pow(position.y - rect.top, 2));
        return distance >= minDistance;
    });
}

function checkInteractions() {
    redDots.forEach((dot, index) => {
        if (isColliding(dot)) {
            console.log(`Collision detected with red dot at index ${index}!`); // Debug log
            dot.remove();
            redDots.splice(index, 1);
	    
            redDotCollected++;
            console.log(`Red dots collected: ${redDotCollected}`); // Debug log
            updateRedDotCounter();
        }
    });

    const door = document.getElementById("door");
    if (door && isColliding(door)) {
        enterDoor();
    }
}

function isColliding(element) {
    const rect1 = { x: playerX, y: playerY, width: FRAME_WIDTH, height: FRAME_HEIGHT };
    const rect2 = element.getBoundingClientRect();

    //console.log(`Player bounds: ${JSON.stringify(rect1)}, Dot bounds: ${JSON.stringify(rect2)}`);

    return !(
        rect1.y + rect1.height < rect2.top ||
        rect1.y > rect2.bottom ||
        rect1.x + rect1.width < rect2.left ||
        rect1.x > rect2.right
    );
}

// ---------------------------------------
// DIALOGUE MANAGEMENT
// ---------------------------------------
function openDialogueBox(dot) {
    toggleMenu(dialogueBox, true);
    dialogueText.textContent = "Why are you touching this dot?";
}

function closeDialogueBox() {
    toggleMenu(dialogueBox, false);
}

// ---------------------------------------
// SAVE/LOAD FUNCTIONALITY
// ---------------------------------------
function saveGame(saveName) {
    const saveData = {
        playerX,
        playerY,
        redDotCollected
    };
    saveStates[saveName] = saveData;
    localStorage.setItem("saveStates", JSON.stringify(saveStates));
}

function loadGame(saveName) {
    const saveData = saveStates[saveName];
    if (!saveData) return;
    playerX = saveData.playerX;
    playerY = saveData.playerY;
    redDotCollected = saveData.redDotCollected;
    updateRedDotCounter();
}

// ---------------------------------------
// INITIALIZATION
// ---------------------------------------
spriteSheet.onload = () => {
    console.log("Sprite sheet loaded!");

    // Handle transparency for white background
    const tempCanvas = document.createElement("canvas");
    const tempCtx = tempCanvas.getContext("2d");
    tempCanvas.width = spriteSheet.width;
    tempCanvas.height = spriteSheet.height;

    tempCtx.drawImage(spriteSheet, 0, 0);
    const imageData = tempCtx.getImageData(0, 0, spriteSheet.width, spriteSheet.height);
    const data = imageData.data;

    for (let i = 0; i < data.length; i += 4) {
        if (data[i] === 255 && data[i + 1] === 255 && data[i + 2] === 255) {
            data[i + 3] = 0; // Set alpha to 0 for white pixels
        }
    }

    tempCtx.putImageData(imageData, 0, 0);

    // Ensure player position is initialized properly
    playerX = canvas.width / 2 - FRAME_WIDTH / 2;
    playerY = canvas.height / 2 - FRAME_HEIGHT / 2;

    // Initialize the game after processing the sprite sheet
    initializeGame();
    gameLoop(0);
};

function initializeGame() {
    console.log("Initializing game...");
    showMainMenu();

    document.addEventListener("keydown", (event) => {
        if (keys[event.key] !== undefined) keys[event.key] = true;
    });

    document.addEventListener("keyup", (event) => {
        if (keys[event.key] !== undefined) keys[event.key] = false;
    });

    document.addEventListener("keydown", (event) => {
        if (event.key === "Escape" && gameContainer.style.display === "block") {
            togglePauseMenu();
        }
    });
}
