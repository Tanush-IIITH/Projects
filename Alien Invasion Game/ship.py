import pygame

class Ship():

        def __init__ (self , screen):
            #Initialize ship and set the starting position
            self.screen = screen

            self.image = pygame.image.load('images/spaceship.bmp')
            self.rect = self.image.get_rect()
            self.screen_rect = screen.get_rect()

            
