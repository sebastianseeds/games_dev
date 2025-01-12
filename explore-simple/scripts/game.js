// ---------------------------------------
// GAME VARIABLES
// ---------------------------------------
const redDots = []; // Store red dot elements
const whiteDots = Array.from(document.querySelectorAll(".interactive-dot"));
const redDotCount = 5; // Number of red dots to generate
const gameWidth = 600; // Width of the game container
const gameHeight = 600; // Height of the game container
const minDistance = 30; // Minimum distance between red and white dots
const speed = 10; // Movement speed in pixels
const option1 = document.getElementById("option1");
const option2 = document.getElementById("option2");

const player = document.getElementById("player");
const dialogueBox = document.getElementById("dialogue-box");
const dialogueText = document.getElementById("dialogue-text");

let redDotCollected = 0; // Number of red dots collected

let saveStates = JSON.parse(localStorage.getItem("saveStates")) || {}; // Load saved games
let currentSaveName = null; // The current save name

// Sprites
// Get the canvas and context
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");

// Main char sprite sheet setup
const spriteSheet = new Image();
spriteSheet.src = "path/to/sprite-sheet.png"; // Replace as necessary

// Sprite frame and movement settings
const FRAME_WIDTH = 64; // Width of each frame
const FRAME_HEIGHT = 64; // Height of each frame
const NUM_FRAMES = 3;    // Number of frames per row
const ANIMATION_SPEED = 8; // Frames to hold each animation frame (lower = faster)

// Player position and animation state
let playerX = 200; // Player's X position on canvas
let playerY = 200; // Player's Y position on canvas
let currentFrame = 0; // Current animation frame
let direction = 3; // Current direction (0 = left, 1 = right, 2 = up, 3 = down)
let frameCount = 0; // Frame counter for animation speed
let isMoving = false;

// Keyboard state tracking
const keys = { ArrowLeft: false, ArrowRight: false, ArrowUp: false, ArrowDown: false };

// ---------------------------------------
// MENU VARIABLES
// ---------------------------------------
const mainMenu = document.getElementById("main-menu");
const settingsMenu = document.getElementById("settings-menu");
const gameContainer = document.getElementById("game-container");
const newGameButton = document.getElementById("new-game");
const continueGameButton = document.getElementById("continue-game");
const settingsButton = document.getElementById("settings");
const returnButton = document.getElementById("return-to-menu");

// ---------------------------------------
// MENU MANAGEMENT
// ---------------------------------------
function showMainMenu() {
    mainMenu.style.display = "flex";
    settingsMenu.style.display = "none";
    gameContainer.style.display = "none";
    toggleRedDotCounter(false); // Hide counter

    document.getElementById("continue-game").addEventListener("click", () => {
        if (Object.keys(saveStates).length > 0) {
            showSaveSelectMenu(); // Go to save selection menu
        } else {
            alert("No saved games available.");
        }
    });
}

function showSaveSelectMenu() {
    const saveSelectMenu = document.getElementById("save-select-menu");
    const savedGamesList = document.getElementById("saved-games-list");
    saveSelectMenu.style.display = "flex";
    savedGamesList.innerHTML = ""; // Clear the list

    Object.keys(saveStates).forEach(saveName => {
        const button = document.createElement("button");
        button.textContent = saveName;
        button.addEventListener("click", () => {
            loadGame(saveName);
            saveSelectMenu.style.display = "none";
            gameContainer.style.display = "block";
            toggleRedDotCounter(true);
        });
        savedGamesList.appendChild(button);
    });

    document.getElementById("return-to-main-menu").addEventListener("click", () => {
        saveSelectMenu.style.display = "none";
        showMainMenu();
    });
}

function showSettingsMenu() {
    mainMenu.style.display = "none";
    settingsMenu.style.display = "flex";
    toggleRedDotCounter(false); // Hide counter
}

function startNewGame() {
    mainMenu.style.display = "none";
    gameContainer.style.display = "block";
    playerX = 300;
    playerY = 300;
    updatePlayerPosition(); // Center the player in the game field
    createRedDots(); // Generate red dots
    createDoor(); // Generate the door
    toggleRedDotCounter(true); // Show counter
}

// Event listeners for menu buttons
newGameButton.addEventListener("click", startNewGame);
continueGameButton.addEventListener("click", () => {
    alert("Continue is not implemented yet!");
});
settingsButton.addEventListener("click", showSettingsMenu);
returnButton.addEventListener("click", showMainMenu);

// ---------------------------------------
// PLAYER MOVEMENT
// ---------------------------------------
document.addEventListener("keydown", (event) => {
    if (isDialogueOpen) return; // Disable movement during dialogue

    switch (event.key) {
        case "ArrowUp": playerY = Math.max(playerY - speed, 0); break;
        case "ArrowDown": playerY = Math.min(playerY + speed, 580); break;
        case "ArrowLeft": playerX = Math.max(playerX - speed, 0); break;
        case "ArrowRight": playerX = Math.min(playerX + speed, 580); break;
    }
    updatePlayerPosition();
});

function updatePlayerPosition() {
    player.style.left = playerX + "px";
    player.style.top = playerY + "px";
    checkInteractions();
}

// ---------------------------------------
// SPRITE ANIMATIONS
// ---------------------------------------
// Event listeners for keyboard input
document.addEventListener("keydown", (e) => {
    if (keys.hasOwnProperty(e.key)) {
        keys[e.key] = true;
        isMoving = true;
    }
});
document.addEventListener("keyup", (e) => {
    if (keys.hasOwnProperty(e.key)) {
        keys[e.key] = false;
        isMoving = false;
    }
});

// Game loop
function gameLoop() {
    // Clear the canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Update player position and direction based on input
    if (keys.ArrowLeft) {
        playerX -= 2;
        direction = 0; // Left
    } else if (keys.ArrowRight) {
        playerX += 2;
        direction = 1; // Right
    } else if (keys.ArrowUp) {
        playerY -= 2;
        direction = 2; // Up
    } else if (keys.ArrowDown) {
        playerY += 2;
        direction = 3; // Down
    }

    // Update the animation frame
    if (isMoving) {
        frameCount++;
        if (frameCount >= ANIMATION_SPEED) {
            currentFrame = (currentFrame + 1) % NUM_FRAMES;
            frameCount = 0;
        }
    } else {
        currentFrame = 1; // Default to standing frame (middle frame of the row)
    }

    // Calculate the source position on the sprite sheet
    const srcX = currentFrame * FRAME_WIDTH;
    const srcY = direction * FRAME_HEIGHT;

    // Draw the current frame of the sprite
    ctx.drawImage(
        spriteSheet,
        srcX, srcY, FRAME_WIDTH, FRAME_HEIGHT, // Source rectangle
        playerX, playerY, FRAME_WIDTH, FRAME_HEIGHT // Destination rectangle
    );

    // Request the next animation frame
    requestAnimationFrame(gameLoop);
}

spritesheet.Onload = () => {
    // Draw the sprite sheet onto the canvas
    ctx.drawImage(spriteSheet, 0, 0);

    // Replace white background with transparency
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;

    for (let i = 0; i < data.length; i += 4) {
        // Check if the pixel is white
        if (data[i] === 255 && data[i + 1] === 255 && data[i + 2] === 255) {
            // Make it transparent
            data[i + 3] = 0;
        }
    }

    ctx.putImageData(imageData, 0, 0);

    gameLoop();
};

// ---------------------------------------
// PLAYER ACTIONS
// ---------------------------------------
document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && gameContainer.style.display === "block") {
        togglePauseMenu();
    }
});

function togglePauseMenu() {
    const pauseMenu = document.getElementById("pause-menu");
    if (pauseMenu.style.display === "none") {
        pauseMenu.style.display = "flex"; // Show menu
    } else {
        pauseMenu.style.display = "none"; // Hide menu
    }
}

// ---------------------------------------
// GAME FUNCTIONS
// ---------------------------------------

function saveGame(saveName) {
    const saveData = {
        playerX,
        playerY,
        redDots: redDots.map(dot => ({
            x: parseInt(dot.style.left),
            y: parseInt(dot.style.top),
        })),
        collected: redDotCollected,
    };
    saveStates[saveName] = saveData;
    localStorage.setItem("saveStates", JSON.stringify(saveStates));
    console.log(`Game saved as "${saveName}"`);
}

function loadGame(saveName) {
    const saveData = saveStates[saveName];
    if (!saveData) {
        console.error("Save not found");
        return;
    }

    // Restore player position
    playerX = saveData.playerX;
    playerY = saveData.playerY;
    redDotCollected = saveData.collected;
    updatePlayerPosition();
    updateRedDotCounter();

    // Restore red dots
    redDots.forEach(dot => dot.remove());
    redDots.length = 0;
    saveData.redDots.forEach(dotData => {
        const redDot = document.createElement("div");
        redDot.classList.add("red-dot");
        redDot.style.left = `${dotData.x}px`;
        redDot.style.top = `${dotData.y}px`;
        gameContainer.appendChild(redDot);
        redDots.push(redDot);
    });
    currentSaveName = saveName;
    console.log(`Game loaded from "${saveName}"`);
}


function createRedDots() {
    debugLog("Creating red dots");
    redDots.forEach(dot => dot.remove());
    redDots.length = 0;

    for (let i = 0; i < redDotCount; i++) {
        const redDot = document.createElement("div");
        redDot.classList.add("red-dot");
        let position;

        do {
            position = {
                x: Math.random() * (gameWidth - 20), // Subtract dot size
                y: Math.random() * (gameHeight - 20)
            };
        } while (!isPositionValid(position));

        debugLog(`Red dot ${i + 1}: (${position.x}, ${position.y})`);
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

function isPositionValid(position) {
    return whiteDots.every(whiteDot => {
        const whiteRect = whiteDot.getBoundingClientRect();
        const whiteX = whiteRect.left;
        const whiteY = whiteRect.top;

        const distance = Math.sqrt(
            Math.pow(position.x - whiteX, 2) + Math.pow(position.y - whiteY, 2)
        );
        return distance >= minDistance;
    });
}

function isColliding(dot) {
    const playerRect = player.getBoundingClientRect();
    const dotRect = dot.getBoundingClientRect();

    return !(
        playerRect.top > dotRect.bottom ||
        playerRect.bottom < dotRect.top ||
        playerRect.left > dotRect.right ||
        playerRect.right < dotRect.left
    );
}

function checkInteractions() {
    if (isDialogueOpen) return; // Skip collision detection if dialogue is open

    whiteDots.forEach((dot) => {
        if (isColliding(dot)) {
            debugLog("Collision detected with a white dot");
            openDialogueBox(dot);
        }
    });

    for (let i = redDots.length - 1; i >= 0; i--) {
        const dot = redDots[i];
        if (isColliding(dot)) {
            debugLog("Collision detected with a red dot");
            dot.remove(); // Remove red dot from DOM
            redDots.splice(i, 1); // Remove red dot from array
            redDotCollected++; // Increment counter
            updateRedDotCounter(); // Update display
        }
    }

    const door = document.getElementById("door");
    if (door && isColliding(door)) {
        enterDoor(); // Trigger door functionality
    }
}

function updateRedDotCounter() {
    const counterElement = document.getElementById("red-dot-counter");
    counterElement.textContent = `Red Dots Collected: ${redDotCollected}`;
}

function createDoor() {
    const door = document.createElement("div");
    door.id = "door";
    door.style.width = "40px";
    door.style.height = "40px";
    door.style.backgroundColor = "blue"; // Door color
    door.style.position = "absolute";

    // Place door on a random side
    const side = Math.floor(Math.random() * 4); // 0: top, 1: right, 2: bottom, 3: left
    if (side === 0) { // Top
        door.style.top = "0px";
        door.style.left = `${Math.random() * (gameWidth - 40)}px`;
    } else if (side === 1) { // Right
        door.style.top = `${Math.random() * (gameHeight - 40)}px`;
        door.style.left = `${gameWidth - 40}px`;
    } else if (side === 2) { // Bottom
        door.style.top = `${gameHeight - 40}px`;
        door.style.left = `${Math.random() * (gameWidth - 40)}px`;
    } else if (side === 3) { // Left
        door.style.top = `${Math.random() * (gameHeight - 40)}px`;
        door.style.left = "0px";
    }

    gameContainer.appendChild(door);
}

function enterDoor() {
    debugLog("Entering door...");
    redDots.forEach(dot => dot.remove()); // Clear current red dots
    document.getElementById("door").remove(); // Remove the door
    createRedDots(); // Generate new red dots
    createDoor(); // Place a new door
    playerX = gameWidth / 2 - 32; // Center the player
    playerY = gameHeight / 2 - 32;
    updatePlayerPosition();
}

function debugLog(message) {
    if (true) { // Set to false to disable debug logs
        console.log(message);
    }
}

document.getElementById("continue-game").addEventListener("click", () => {
    togglePauseMenu();
});

document.getElementById("save-game").addEventListener("click", () => {
    const saveName = currentSaveName || prompt("Enter a name for your save:");
    if (saveName) {
        saveGame(saveName);
        currentSaveName = saveName;
        togglePauseMenu(); // Hide the pause menu
    }
});

document.getElementById("save-and-exit-game").addEventListener("click", () => {
    const saveName = currentSaveName || prompt("Enter a name for your save:");
    if (saveName) {
        saveGame(saveName);
        currentSaveName = saveName;
        togglePauseMenu(); // Hide the pause menu
        showMainMenu(); // Return to the main menu
    }
});

document.getElementById("exit-game").addEventListener("click", () => {
    togglePauseMenu(); // Hide the pause menu
    showMainMenu(); // Return to the main menu
});

// ---------------------------------------
// DIALOGUE MANAGEMENT
// ---------------------------------------
function openDialogueBox(dot) {
    isDialogueOpen = true;
    dialogueBox.style.display = "block";
    dialogueText.textContent = getRandomRidiculousText();
}

function closeDialogueBox() {
    console.log("Closing dialogue box"); // Debugging log
    isDialogueOpen = false;
    dialogueBox.style.display = "none";
}

function getRandomRidiculousText() {
    const texts = [
        "Why are you even touching this dot?",
        "This dot holds the secrets of the universe... or maybe not.",
        "Do you feel lucky, dot-toucher?",
        "Congratulations, you found... nothing!",
    ];
    return texts[Math.floor(Math.random() * texts.length)];
}

option1.addEventListener("click", () => {
    console.log("Option 1 clicked");
    closeDialogueBox();
});
option2.addEventListener("click", () => {
    console.log("Option 2 clicked");
    closeDialogueBox();
});

// ---------------------------------------
// INITIALIZATION
// ---------------------------------------
function initializeGame() {
    showMainMenu(); // Show the main menu by default
    isDialogueOpen = false; // Reset dialogue state
    gameContainer.style.display = "none"; // Ensure game container is hidden
    settingsMenu.style.display = "none"; // Ensure settings menu is hidden
}
initializeGame();

// ---------------------------------------
// GAME VARIABLES
// ---------------------------------------
const canvas = document.getElementById("gameCanvas");
const ctx = canvas.getContext("2d");

// Sprite sheet details
const spriteSheet = new Image();
spriteSheet.src = "/Users/sebastianseeds/games_dev/explore-simple/images/ex_player_ss.png";

// Frame and animation details
const FRAME_WIDTH = 66; // Frame width in pixels
const FRAME_HEIGHT = 100; // Frame height in pixels
const COLUMNS = 4; // Frames per row
const ROWS = 4; // Total rows
const ANIMATION_SPEED = 100; // Milliseconds per frame

// Player state
let currentFrame = 0; // Current frame index
let currentRow = 0; // Default: Walking down
let lastUpdateTime = 0; // Time tracking for animation

// Player position on the canvas
let playerX = 100; // X-coordinate
let playerY = 100; // Y-coordinate
const speed = 5; // Movement speed

// ---------------------------------------
// GAME LOOP
// ---------------------------------------
function gameLoop(timestamp) {
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Update animation frame
    if (timestamp - lastUpdateTime > ANIMATION_SPEED) {
        currentFrame = (currentFrame + 1) % COLUMNS; // Cycle through frames
        lastUpdateTime = timestamp;
    }

    // Draw the current frame of the sprite
    ctx.drawImage(
        spriteSheet, 
        currentFrame * FRAME_WIDTH, // Source X
        currentRow * FRAME_HEIGHT, // Source Y
        FRAME_WIDTH, FRAME_HEIGHT, // Source width/height
        playerX, playerY,          // Destination X/Y
        FRAME_WIDTH, FRAME_HEIGHT  // Destination width/height
    );

    requestAnimationFrame(gameLoop);
}

// ---------------------------------------
// INPUT HANDLING
// ---------------------------------------
document.addEventListener("keydown", (event) => {
    switch (event.key) {
        case "ArrowDown":
            playerY += speed; // Move down
            currentRow = 0; // Row 1: Walking down
            break;
        case "ArrowUp":
            playerY -= speed; // Move up
            currentRow = 1; // Row 2: Walking up
            break;
        case "ArrowLeft":
            playerX -= speed; // Move left
            currentRow = 2; // Row 3: Walking left
            break;
        case "ArrowRight":
            playerX += speed; // Move right
            currentRow = 3; // Row 4: Walking right
            break;
    }
});

// ---------------------------------------
// LOAD SPRITE SHEET AND START GAME
// ---------------------------------------
spriteSheet.onload = () => {
    gameLoop(0); // Start the game loop
};
