/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2026 SEN Labs e.U.
 */

/**
 * The spinner item of the menus of relations (SpinnerMenuItem of senryu/src/kits/tracker) in a menu on the screen: it takes steps for a while, and screenshots are taken of three of
 * them. spinner.sh builds and runs it. Needs a desktop; the screenshots are /tmp/spinner-1.png ... -3.png.
 */
#include <Application.h>
#include <MenuItem.h>
#include <PopUpMenu.h>
#include <Screen.h>
#include <OS.h>

#include <stdlib.h>

#include "SpinnerMenuItem.h"

int
main(int argc, char** argv)
{
	BApplication app("application/x-vnd.sen-labs.spinner-test");
	BPopUpMenu* menu = new BPopUpMenu("relations", false, false);
	menu->AddItem(new BMenuItem("Stephansdom", NULL));
	SpinnerMenuItem* spinner = new SpinnerMenuItem("Fetching relations" B_UTF8_ELLIPSIS);
	spinner->SetEnabled(false);
	menu->AddItem(spinner);
	menu->AddItem(new BMenuItem("Karlskirche", NULL));
	spinner->StartSpinning();
	menu->Go(BPoint(300, 300), false, true, true);

	for (int frame = 0; frame < 40; frame++) {
		snooze(80000);
		spinner->NextFrame();
		if (frame == 8 || frame == 11 || frame == 14) {
			BString command("screenshot -s -f png /tmp/spinner-");
			command << (frame == 8 ? 1 : frame == 11 ? 2 : 3) << ".png";
			system(command.String());
		}
	}
	return 0;
}
