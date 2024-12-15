#include <iostream>
#include <raylib.h>
#include <vector>
#include <fstream>
using namespace std;

const int screen_width = 500;
const int screen_height = 450;
bool gameOver = false;
int liveCout = 5;
int player_score = 0;
int Highscore = 0;
const char *highscore_file = "highscore.txt";
Sound hitSound;

enum Screen
{
    MENU,
    PLAY,
    MIDDLE,
    HARD,
    EASY,
    TUTORIAL,
    GAMEOVER,
    WIN,
};

void SaveHighscore()
{
    ofstream file(highscore_file);
    if (file.is_open())
    {
        file << Highscore;
        file.close();
    }
}

void LoadHighscore()
{
    ifstream file(highscore_file);
    if (file.is_open())
    {
        file >> Highscore;
        file.close();
    }
}

class Button
{
private:
    float x, y;
    float width, height; // ukuran
    const char *text;

public:
    Button(float _x, float _y, int _width, int _height, const char *_text)
    {
        x = _x;
        y = _y;
        width = _width;
        height = _height;
        text = _text;
    };

    void Draw()
    {
        DrawRectangle(x, y, width, height, WHITE);
        DrawText(text, x + width / 2 - MeasureText(text, 20) / 2, y + height / 2 - 10, 20, BLACK);
    }

    bool IsClicked()
    {
        if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON))
        {
            Vector2 mousePoint = GetMousePosition();
            Rectangle rect = {x, y, width, height};
            if (CheckCollisionPointRec(mousePoint, rect))
            {
                return true;
            }
        }
        return false;
    }
};

class Racket
{
public:
    float x, y;
    float widht, height;
    int speed;

    Racket(int _x, int _y, int _widht, int _height, int _speed)
    {
        x = _x;
        y = _y;
        widht = _widht;
        height = _height;
        speed = _speed;
    }

    void Draw()
    {
        DrawRectangle(x, y, widht, height, BLACK);
    };

    void Update()
    {
        if (IsKeyDown(KEY_LEFT))
        {
            x = x - speed;
        };
        if (IsKeyDown(KEY_RIGHT))
        {
            x = x + speed;
        };
        if (x <= 0)
        {
            x = 0;
        }
        if (x + widht >= GetScreenWidth()) // batas
        {
            x = GetScreenWidth() - widht;
        }
    }
};

class Balok
{
public:
    float x, y;
    float width, height;

    Balok(int _x, int _y, int _width, int _height)
    {
        x = _x;
        y = _y;
        width = _width;
        height = _height;
    }

    void Draw()
    {
        DrawRectangle(x, y, width, height, WHITE);
    };
};

class Bola
{
public:
    float x, y;
    int speed_x, speed_y;
    int radius;
    bool isMoving;

    Bola(float _x, float _y, int _speedX, int _speedY, int _radius)
    {
        x = _x;
        y = _y;
        speed_x = _speedX;
        speed_y = _speedY;
        radius = _radius;
        isMoving = false;
    }

    void Update()
    {
        if (IsKeyPressed(KEY_SPACE))
        {
            isMoving = true;
        }

        if (isMoving)
        {
            x += speed_x;
            y += speed_y;

            if (y - radius <= 60)
            {
                speed_y *= -1;
            }

            if (x + radius >= GetScreenWidth() || x - radius <= 0)
            {
                speed_x *= -1;
            }

            if (y + radius >= GetScreenHeight())
            {
                ResetBola();
            }
        }
        else
        {
            x = racket->x + racket->widht / 2;
        }
    }

    void Draw()
    {
        DrawCircle(x, y, radius, BLACK);
    }

    void ResetBola() // menghilangkan bola ketika melebihi layar
    {
        x = screen_width / 2;
        y = GetScreenHeight() - 40;
        int speed_choices[2] = {-1, 1};
        speed_x *= speed_choices[GetRandomValue(0, 0)];
        speed_y = -abs(speed_y);
        isMoving = false;
        liveCout -= 1;
    }

    void SetRacket(Racket *r) //
    {
        racket = r;
    }

private:
    Racket *racket;
};

class Live : public Bola
{
public:
    Live() : Bola(420, 30, 1, 3, 10) {}

    void Draw()
    {
        DrawCircle(x, y, radius, RED);
    }

    void Update()
    {
        if (liveCout <= 0)
        {
            ClearBackground(BLACK);
        }
    }
};

// level
class Easy
{
public:
    Racket racket;
    Bola bola;
    std::vector<Live> liveList;
    std::vector<Balok> balokList;
    Screen currentScreen;

    Easy() : racket(screen_width / 2 - 100 / 2, screen_height - 30, 100, 10, 7), bola(screen_width / 2, screen_height - 40, 4, 4, 10), liveList()
    {
        bola.SetRacket(&racket);
        int rows = 5;
        int cols = 14;
        int brickWidth = 35;
        int brickHeight = 20;
        int spacing = 1;
        int yOffset = 50;
        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                Balok brick(j * (brickWidth + spacing), yOffset + i * (brickHeight + spacing), brickWidth, brickHeight);
                balokList.push_back(brick);
            }
        }

        for (int i = 0; i < 5; i++)
        {
            Live lives;
            lives.x = 400 + i * (lives.radius + 10);
            liveList.push_back(lives);
        }
    }

    void Update(Screen &currentScreen)
    {
        racket.Update();
        bola.Update();

        // cek benturan
        if (CheckCollisionCircleRec(Vector2{bola.x, bola.y}, bola.radius, Rectangle{racket.x, racket.y, racket.widht, racket.height - 10}))
        {
            bola.speed_y *= -1;
            PlaySound(hitSound); // Play ting sound
        }

        for (int i = 0; i < balokList.size(); i++)
        {
            if (CheckCollisionCircleRec(Vector2{bola.x, bola.y}, bola.radius, Rectangle{balokList[i].x, balokList[i].y, balokList[i].width, balokList[i].height}))
            {
                bola.speed_y *= -1;
                balokList.erase(balokList.begin() + i);
                player_score += 1;
                PlaySound(hitSound); // Play ting sound

                if (player_score > Highscore)
                {
                    Highscore = player_score;
                    SaveHighscore();
                }
                if (balokList.size() == 0)
                {
                    currentScreen = MIDDLE;
                }
            }
        }

        while (liveList.size() > liveCout)
        {
            liveList.pop_back();
        }

        for (Live &lives : liveList)
        {
            lives.Update();
        }

        if (balokList.empty())
        {
            currentScreen = MIDDLE;
        }
    }

    void Draw()
    {
        racket.Draw();
        bola.Draw();
        for (Balok &brick : balokList)
        {
            brick.Draw();
        }
        for (Live &lives : liveList)
        {
            lives.Draw();
        }
    }
};

class Middle
{
public:
    Racket racket;
    Bola bola;
    std::vector<Live> liveList;
    std::vector<Balok> balokList;
    Screen currentScreen;

    Middle() : racket(screen_width / 2 - 100 / 2, screen_height - 30, 100, 10, 7), bola(screen_width / 2, screen_height - 40, 4, 5, 10), liveList()
    {
        Init();
    }

    void Init()
    {
        balokList.clear();
        liveList.clear();

        int rows = 5;
        int cols = 14;
        int brickWidth = 35;
        int brickHeight = 20;
        int spacing = 1;
        int yOffset = 50;
        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                Balok brick(j * (brickWidth + spacing), yOffset + i * (brickHeight + spacing), brickWidth, brickHeight);
                balokList.push_back(brick);
            }
        }

        for (int i = 0; i < 4; i++)
        {
            Live lives;
            lives.x = 400 + i * (lives.radius + 10);
            liveList.push_back(lives);
        }

        bola.SetRacket(&racket);
    }

    void Update(Screen &currentScreen)
    {
        racket.Update();
        bola.Update();

        if (CheckCollisionCircleRec(Vector2{bola.x, bola.y}, bola.radius, Rectangle{racket.x, racket.y, racket.widht, racket.height - 10}))
        {
            bola.speed_y *= -1;
            PlaySound(hitSound); // Play ting sound
        }

        for (int i = 0; i < balokList.size(); i++)
        {
            if (CheckCollisionCircleRec(Vector2{bola.x, bola.y}, bola.radius, Rectangle{balokList[i].x, balokList[i].y, balokList[i].width, balokList[i].height}))
            {
                bola.speed_y *= -1;
                balokList.erase(balokList.begin() + i);
                player_score += 1;
                PlaySound(hitSound); // Play ting sound

                if (player_score > Highscore)
                {
                    Highscore = player_score;
                    SaveHighscore();
                }
                if (balokList.size() == 0)
                {
                    currentScreen = HARD;
                }
            }
        }

        while (liveList.size() > liveCout)
        {
            liveList.pop_back();
        }

        for (Live &lives : liveList)
        {
            lives.Update();
        }

        if (balokList.empty())
        {
            currentScreen = HARD;
        }
    }

    void Draw()
    {
        racket.Draw();
        bola.Draw();
        for (Balok &brick : balokList)
        {
            brick.Draw();
        }
        for (Live &lives : liveList)
        {
            lives.Draw();
        }
    }
};

class Hard
{
public:
    Racket racket;
    Bola bola;
    std::vector<Live> liveList;
    std::vector<Balok> balokList;
    Screen currentScreen;

    Hard() : racket(screen_width / 2 - 100 / 2, screen_height - 30, 100, 10, 7), bola(screen_width / 2, screen_height - 40, 4, 6, 10), liveList()
    {
        Init();
    }

    void Init()
    {
        balokList.clear();
        liveList.clear();

        int rows = 6;
        int cols = 14;
        int brickWidth = 35;
        int brickHeight = 20;
        int spacing = 1;
        int yOffset = 50;
        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                Balok brick(j * (brickWidth + spacing), yOffset + i * (brickHeight + spacing), brickWidth, brickHeight);
                balokList.push_back(brick);
            }
        }

        for (int i = 0; i < 3; i++)
        {
            Live lives;
            lives.x = 400 + i * (lives.radius + 10);
            liveList.push_back(lives);
        }

        bola.SetRacket(&racket);
    }

    void Update(Screen &currentScreen)
    {
        racket.Update();
        bola.Update();

        if (CheckCollisionCircleRec(Vector2{bola.x, bola.y}, bola.radius, Rectangle{racket.x, racket.y, racket.widht, racket.height - 10}))
        {
            bola.speed_y *= -1;
            PlaySound(hitSound); // Play ting sound
        }

        for (int i = 0; i < balokList.size(); i++)
        {
            if (CheckCollisionCircleRec(Vector2{bola.x, bola.y}, bola.radius, Rectangle{balokList[i].x, balokList[i].y, balokList[i].width, balokList[i].height}))
            {
                bola.speed_y *= -1;
                balokList.erase(balokList.begin() + i);
                player_score += 1;
                PlaySound(hitSound); // Play ting sound

                if (player_score > Highscore)
                {
                    Highscore = player_score;
                    SaveHighscore();
                }
                if (balokList.size() == 0)
                {
                    currentScreen = MENU; // Game finished, back to menu
                }
            }
        }

        while (liveList.size() > liveCout)
        {
            liveList.pop_back();
        }

        for (Live &lives : liveList)
        {
            lives.Update();
        }

        if (balokList.empty())
        {
            currentScreen = WIN; // Game finished, back to menu
        }
    }

    void Draw()
    {
        racket.Draw();
        bola.Draw();
        for (Balok &brick : balokList)
        {
            brick.Draw();
        }
        for (Live &lives : liveList)
        {
            lives.Draw();
        }
    }
};

class Tutorial
{
public:
    Tutorial() : back(screen_width / 2 + 400, screen_height - 20, 100, 50, "back") {} // constructor

    void Update(Screen &currentScreen)
    {
        if (back.IsClicked())
        {
            currentScreen = MENU; // Kembali ke menu saat tombol 'back' ditekan
        }
    }

    void Draw()
    {
        DrawText("Tutorial", screen_width / 2 - MeasureText("Tutorial", 30) / 2, screen_height / 4 + 50, 30, BLACK);
        DrawText("How to Play:", 50, screen_height / 4 + 80, 20, BLACK);
        DrawText("-Use LEFT and RIGHT arrow keys to move the racket", 50, screen_height / 4 + 100, 15, BLACK);
        DrawText("-Press SPACE to release the ball and start the game", 50, screen_height / 4 + 120, 15, BLACK);
        DrawText("-Break all the bricks with the ball to score points", 50, screen_height / 4 + 140, 15, BLACK);
        DrawText("-Don't let the ball fall below the racket or you lose a life", 50, screen_height / 4 + 160, 15, BLACK);
        DrawText("-Press ENTER to MENU", 50, screen_height / 4 + 180, 15, BLACK);
        back.Draw();
    }

private:
    Button back;
};

class Menu // class menu //aman sih
{
public:
    Menu() : play(screen_width / 2 - 100 / 2, 200, 100, 50, "play"), tutorial1(screen_width / 2 - 100 / 2, screen_height / 2 + 50, 100, 50, "tutorial") {} // constructor

    void Update(Screen &currentScreen) // fungsi update
    {
        if (play.IsClicked()) // jika di klik
        {
            currentScreen = EASY; // ke layar permainan
        }
        if (tutorial1.IsClicked()) //
        {
            currentScreen = TUTORIAL; // ke tutorial
        }
    }

    void Draw()
    {
        DrawText("Main Menu", screen_width / 2 - MeasureText("Main Menu", 40) / 2, screen_height / 4, 40, BLACK);
        play.Draw();
        tutorial1.Draw();
    }

private:
    Button play;
    Button tutorial1;
};

class Game
{
public:
    Game() : currentScreen(MENU), menu(), easy(), middle(), hard(), tutorial() {}

    void Init()
    {
        InitWindow(screen_width, screen_height, "Arkanoid Game");
        SetTargetFPS(60);
    }

    void Update()
    {
        switch (currentScreen)
        {
        case MENU:
            menu.Update(currentScreen);
            break;
        case EASY:
            easy.Update(currentScreen);
            break;
        case MIDDLE:
            middle.Update(currentScreen);
            break;
        case HARD:
            hard.Update(currentScreen);
            break;
        case TUTORIAL:
            if (IsKeyPressed(KEY_ENTER))
            {
                currentScreen = MENU;
            }
            tutorial.Update(currentScreen);
            break;
        case GAMEOVER:
            if (IsKeyPressed(KEY_ENTER))
            {
                currentScreen = MENU;
                player_score = 0;
                liveCout = 5;
                easy = Easy();
                middle = Middle();
                hard = Hard();
            }
            break;
        case WIN:
            if (IsKeyPressed(KEY_ENTER))
            {
                currentScreen = MENU;
                player_score = 0;
                liveCout = 5;
                easy = Easy();
                middle = Middle();
                hard = Hard();
            }
            break;
        }
    }

    void Draw()
    {
        BeginDrawing();
        ClearBackground(SKYBLUE);

        switch (currentScreen)
        {
        case MENU:
            menu.Draw();
            break;
        case EASY:
            DrawText(TextFormat("Highscore : %i", Highscore), 0, 0, 20, WHITE);
            DrawText(TextFormat("Score : %i", player_score), 0, 20, 20, WHITE);
            DrawText(TextFormat("Level 1"), 420, 0, 20, WHITE);
            easy.Draw();
            break;
        case MIDDLE:
            DrawText(TextFormat("Highscore : %i", Highscore), 0, 0, 20, WHITE);
            DrawText(TextFormat("Score : %i", player_score), 0, 20, 20, WHITE);
            DrawText(TextFormat("Level 2"), 420, 0, 20, WHITE);
            middle.Draw();
            break;
        case HARD:
            DrawText(TextFormat("Highscore : %i", Highscore), 0, 0, 20, WHITE);
            DrawText(TextFormat("Score : %i", player_score), 0, 20, 20, WHITE);
            DrawText(TextFormat("Level 3"), 420, 0, 20, WHITE);
            hard.Draw();
            break;
        case TUTORIAL:
            DrawText(TextFormat("Highscore : %i", Highscore), 0, 0, 20, WHITE);
            DrawText(TextFormat("Score : %i", player_score), 0, 20, 20, WHITE);
            DrawText(TextFormat("Level "), 420, 0, 20, WHITE);
            tutorial.Draw();
            easy.Draw();
            break;
        case GAMEOVER:
            DrawText("Game Over", screen_width / 2 - MeasureText("Game Over", 40) / 2, screen_height / 4 + 20, 50, BLACK);
            DrawText(TextFormat("Final Score : %i", player_score), screen_width / 2 - MeasureText(TextFormat("Final Score : %i", player_score), 20) / 2, screen_height / 4 + 70, 20, BLACK);
            DrawText(TextFormat("Highscore : %i", Highscore), screen_width / 2 - MeasureText(TextFormat("Highscore : %i", Highscore), 20) / 2, screen_height / 4 + 90, 20, BLACK);
            break;
        case WIN:
            DrawText("WIN", screen_width / 2 - MeasureText("Game Over", 40) / 2, screen_height / 4 + 20, 50, BLACK);
            DrawText(TextFormat("Final Score : %i", player_score), screen_width / 2 - MeasureText(TextFormat("Final Score : %i", player_score), 20) / 2, screen_height / 4 + 70, 20, BLACK);
            DrawText(TextFormat("Highscore : %i", Highscore), screen_width / 2 - MeasureText(TextFormat("Highscore : %i", Highscore), 20) / 2, screen_height / 4 + 90, 20, BLACK);
            break;
        }

        EndDrawing();
    }

    void Run()
    {
        Init();

        // Load highscore from file
        LoadHighscore();

        // Load music
        InitAudioDevice();
        Music music = LoadMusicStream("bacground_music.mp3");
        PlayMusicStream(music);
        hitSound = LoadSound("tingsound.mp3");

        while (!WindowShouldClose() && !gameOver)
        {
            UpdateMusicStream(music);
            Update();

            if (liveCout <= 0)
            {
                currentScreen = GAMEOVER;
            }

            Draw();
        }

        UnloadMusicStream(music);
        CloseAudioDevice();

        CloseWindow();
    }

private:
    Menu menu;
    Easy easy;
    Middle middle;
    Hard hard;
    Tutorial tutorial;
    Screen currentScreen;
};

int main()
{
    Game game;
    game.Run();

    return 0;
}
// alhamdulillah
