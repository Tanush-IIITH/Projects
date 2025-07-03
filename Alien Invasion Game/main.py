import sys

import pygame

from settings import Settings

def run_game():
    #Start the game and create an object screen
    pygame.init()
    alien_settings = Settings()
    screen = pygame.display.set_mode((alien_settings.screen_width, alien_settings.screen_height))
    pygame.display.set_caption("Alien Invasion")

    #Background color
    bg_color = alien_settings.bg_color

    #Main loop for the game
    while True:
        #Look for keyboard and mouse events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()

        #Assign the background color to the screen
        screen.fill(bg_color)

        #Most recently drawn screen
        pygame.display.flip()

run_game() #to run the game
