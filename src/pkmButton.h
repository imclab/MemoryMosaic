/*
 *  pkmButton.h
 *  oramics
 *
 *  Created by Mr. Magoo on 6/18/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#include <vector.h>
#include <string.h>
#include "ofMain.h"
#include "pkmFonts.h"

template <class T>
inline bool within(T xt, T yt, 
				   T x, T y, T w, T h)
{
	return xt > x && xt < (x+w) && yt > y && yt < (y+h);
}



/**************************************/

enum BUTTON_TYPE {
	TOGGLE,
	SELECT
};

class pkmButton
{
public:
	pkmButton()
	{
		label = "";
		_x = 0;
		_y = 0;
		_w = 0;
		_h = 0;
		bActive = false;
		_type = TOGGLE;
		_func = 0;
        myFont.loadFont("Dekar.ttf", 14, true);
	}
	pkmButton(string l, int x, int y, int w, int h, bool active = false, 
			  int x_off = 5, int y_off = 0, 
			  BUTTON_TYPE buttontype = TOGGLE,
			  void (*func)(int, bool) = 0)
	{
		label = l;
		_x = x;
		_y = y;
		_x_offset = x_off;
		_y_offset = y_off;
		_w = w;
		_h = h;
		bActive = active;
		_type = buttontype;
		_func = func;
        myFont.loadFont("Dekar.ttf", 14, true);
	}
	
	void draw()
	{
		ofSetColor(255, 255, 255);
		if (bActive) {
			ofFill();
			ofRect(_x, _y, _w, _h);
			ofSetColor(0, 0, 0);
			myFont.drawString(label, _x+_x_offset, _y+_y_offset);
		}
		else {
			ofNoFill();
			ofRect(_x, _y, _w, _h);
			ofSetColor(255, 255, 255);
			myFont.drawString(label, _x+_x_offset, _y+_y_offset);
		}
		
		
	}
	
	bool touchDown(int x, int y, int arg = 0)
	{
		if(within<int>(x, y, _x, _y, _w, _h))
		{
			if (_func != 0) 
			{
				(*_func)(arg, bActive);			
			}
			if( _type == SELECT && !bActive )
			{
				bActive = true;
				return true;
			}
			else if(_type == TOGGLE)
			{
				bActive = !bActive;
				return bActive;
			}
			else {
				return false;
			}

		}
		else {
			return false;
		}

	}
	
	void touchUp(int x, int y)
	{
		if( _type == SELECT )
		{
			bActive = false;
		}
	}
	
    ofTrueTypeFont myFont;
	void (*_func)(int, bool);
	int _x, _y, _w, _h;
	int _x_offset, _y_offset;  // offset for text within button
	BUTTON_TYPE _type;
	string label;
	bool bActive;
};


/**************************************/

// behavior for toggle buttons
enum BEHAVIOR_TYPE {
	SINGLE,
	RANGE
};


class pkmButtonList
{
public:
	
	pkmButtonList()
	{
		_x = 0;
		_y = 0;
		label = "";
		behavior_type = SINGLE;
        myFont.loadFont("Dekar.ttf", 14, true);
	}
	
	void add(string l, int x, int y, int w, int h, 
			 bool active = false, 
			 int _x_off = 5, int _y_off = 0, 
			 BUTTON_TYPE buttontype = TOGGLE, 
			 void (*func)(int, bool) = 0)
	{
		buttonList.push_back(pkmButton(l, x, y, w, h,
									   active, 
									   _x_off, _y_off, 
									   buttontype, 
									   func));
	}
	
	void draw()
	{
		ofSetColor(255, 255, 255);
		myFont.drawString(label, _x, _y);
		ofPushMatrix();
		ofTranslate(_x, _y, 0);
		for (vector<pkmButton>::iterator it = buttonList.begin(); it != buttonList.end(); it++) {
			(*it).draw();
		}
		ofPopMatrix();
	}
	
	void touchDown(int x, int y)
	{
		int i = 0;
		for (vector<pkmButton>::iterator it = buttonList.begin(); it != buttonList.end(); it++) 
		{
			bool bDidToggleOn = (*it).touchDown(x-_x, // draw within container so need to offset touch coordinates
												y-_y, 
												i++); // pass an argument which is the button's list number to the function callback within the button class
			// if the btuton is turned on, and we only want one button for the list (SINGLE)
			if(bDidToggleOn && behavior_type == SINGLE)
			{
				// unselect all the other buttons
				for (vector<pkmButton>::iterator it2 = buttonList.begin(); it2 != buttonList.end(); it2++) {
					if (it != it2) {
						it2->bActive = false;
					}
				}
				// and exit
				break;
			}
		}
	}
	
	void resetTo(int active_button_number)
	{
		int i = 0;
		for (vector<pkmButton>::iterator it = buttonList.begin(); it != buttonList.end(); it++) 
		{
			if (i == active_button_number) {
				it->bActive = true;
				// unselect all the other buttons
				for (vector<pkmButton>::iterator it2 = buttonList.begin(); it2 != buttonList.end(); it2++) {
					if (it != it2) {
						it2->bActive = false;
					}
				}
				// and exit
				break;
			}
			i++;
		}
	}
	
	int _x, _y;
	string label;
	vector<pkmButton> buttonList;
	BEHAVIOR_TYPE behavior_type;
    ofTrueTypeFont myFont;
};
