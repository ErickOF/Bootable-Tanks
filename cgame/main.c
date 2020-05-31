#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h> 

#define KNRM  "\033[0m"
#define KRED  "\033[31m"
#define KGRN  "\033[32m"
#define KYEL  "\033[33m"
#define KBLU  "\033[34m"
#define KMAG  "\033[35m"
#define KCYN  "\033[36m"
#define KWHT  "\033[37m"



#define clear() printf("\033[H\033[J")
#define gotoxy(x,y) printf("\033[%d;%dH", (y), (x))
#define to_red() printf("\033[1;31m")
#define to_yellow() printf("\033[1;33m")
#define reset() printf("\033[0m")



#define randint(minimum_number,max_number) rand() % (max_number  - minimum_number) + minimum_number


#define num_enemies 2
#define num_tanks (num_enemies+1)


char matrix[48][64];

typedef struct Object{
    int i;
    int x;
    int y;
    int team;
    int type;    
}Object;

void new_matrix(){
    int i;
    int j;
    for (i = 0; i< 48; ++i){
        for (j = 0; j<64; ++j){
            if(i==j || i == 20){
                matrix[i][j] = '1';    
            }else{
                matrix[i][j] = '0';
            }
            
        }

    }
}


void draw_matrix(){
    int i , j;
    char cur ;
    //gotoxy(0, 0);
    for (i = 0; i< 48; ++i){
        gotoxy(0, i+1);
        for (j = 0; j<64; ++j){
            gotoxy(j+1, i+1);
            cur = matrix[i][j];
            if (cur == '1'){
                printf(KRED);
                printf("▉");
            }else{                
                printf("%c",cur);
            }
            reset();
        }

        printf("\t\t(%d)",i);
    }
    printf("\n");
}



int move_object(int dir, Object* o){  
    //printf("dir: %d\n", dir);
    int out = 0;
    //printf("o: %d, %d\n", o->x, o->y);
    if (dir < 5 && dir >0){
        o->type = dir;
    }
    if (dir == 1){
        o->x += 1;
    }
    if (dir == 2){
        o->y += 1;
    }
    if (dir == 3){
        o->x -= 1;
    }
    if (dir == 4){
        o->y -= 1;
    }    
    if(o->x < 0){o->x = 0;out =1;}
    if(o->x > 63){o->x = 63;out=1;}
    if(o->y < 0){o->y = 0;out=1;}
    if(o->y > 47){o->y = 47;out=1;}
    
    //printf("o: %d, %d\n", o->x, o->y);
    return out;
}



void newbullet(Object* tank, Object* bullet){
    if (bullet->i == 0){
        bullet->i = 1;    
        bullet->x = tank->x;
        bullet->y = tank->y;
        bullet->team = tank->team;
        bullet->type = (tank->type)+4; //57 horizontal
    }
    
}

void simulate_interrupt(Object* tanks, Object* bullets){
    int dir;
    dir = randint(0,5);    
    move_object(dir, tanks);
    if (dir == 0){
        newbullet(tanks , bullets );
    }

}


void move_tanks(Object* tanks, Object* bullets,  int size){
    int dir;
    
    for (int t=1; t< size; t++){
        if (tanks[t].i){
            dir = randint(0,5);
            move_object(dir, tanks + t);
            if (dir == 0){
                newbullet(tanks + t, bullets + t);
            }
        }
    }
    
}

void move_bullets(Object* bullets,  int size){
    int dir, out;
    
    for (int b=0; b< size; b++){
        if (bullets[b].i){            
            dir = (bullets[b].type)-4;
            out = move_object(dir, bullets + b);
            bullets[b].type = dir + 4; //restores type
            if (out){
                bullets[b].i = 0;
            }
        }
    }    
}


void drawObject(Object* o){
    gotoxy(o->x+1, o->y+1);
    
    if (o->team == 0){
        printf(KBLU);
    }else{
        printf(KYEL);
    }
    if (o->type == 1){
        printf("⇨");
    }
    if (o->type == 2){
        printf("⇩");
    }
    if (o->type == 3){
        printf("⇦");
    }
    if (o->type == 4){
        printf("⇧");
    }


    if (o->type == 5){
        printf("-");
    }
    if (o->type == 6){
        printf("|");
    }
    if (o->type == 7){
        printf("-");
    }
    if (o->type == 8){
        printf("|");
    }
    

    //printf("object: %d,%d,%d,%d\n", o->x, o->y, o->team, o->c);    

    reset();

}


int drawEntities(Object* tanks, Object* bullets, int size){
    int t, b;
    
    for (t=0; t< size; t++){
        if (tanks[t].i){
            drawObject(tanks + t);
        }
    }

    for (b=0; b< size; b++){
        if (bullets[b].i){
            drawObject(bullets + b);
        }
    }
}

int gameloop(Object* tanks, Object* bullets, int size){
    int counter = 1;
    while(counter < 200){
        draw_matrix();
        move_tanks(tanks, bullets, size);

        if (counter%2){
            simulate_interrupt(tanks, bullets);
        }

        move_bullets(bullets, size);
        drawEntities(tanks, bullets, size);
        gotoxy(0, 50);
        //printf("");
        fflush(stdout);
        //printf("object: %d,%d,%d,%c\n", player->x, player->y, player->team, player->c);    
        usleep(100000);
        counter += 1;
    }
    
    gotoxy(0, 50);
}



void newObject(Object* o, int i , int x, int y, int team, int type){
    o->i = i;
    o->x = x;
    o->y = y;
    o->team = team;
    o->type = type;
}

int main(void)
{
    srand(time(NULL));
    system("clear");
    
    Object tanks[num_tanks];
    newObject(tanks,1, 30,40, 0,0);
    for (int t = 1; t < num_tanks; ++t){
        newObject(tanks+t,1, 15*t,20, 1,0);        
    }
        
    Object bullets[num_tanks];


    for (int b = 0; b < num_tanks; ++b){
        newObject(bullets+b,0, 0,0, 0,0);        
    }
      

    
    clear();
    new_matrix();

    gameloop(tanks, bullets, num_tanks);    

    return 0;
}