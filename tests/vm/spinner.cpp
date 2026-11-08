/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2026 SEN Labs e.U.
 */

/**
 * The menu of the targets of a relation while the navigator is working (OpenRelationTargetsMenu of senryu/src/kits/tracker, which needs Tracker to run): the same steps in a menu
 * on the screen. It opens with "Fetching relations..." and a spinner (SpinnerMenuItem) that turns by messages of a BMessageRunner, and when the thread that waits for the answer says that
 * it is in (a message to the menu) the items take the place of the placeholder in the menu that is open. Screenshots of the three states: /tmp/spinner-1.png (fetching),
 * -2.png (a moment later: the spinner has turned), -3.png (the items). spinner.sh builds and runs it. Needs a desktop.
 */
#include <Application.h>
#include <MenuItem.h>
#include <MessageRunner.h>
#include <PopUpMenu.h>
#include <Screen.h>
#include <OS.h>

#include <stdlib.h>
#include <thread>

#include "SpinnerMenuItem.h"

static const uint32 kFetched = 'sfdn', kTick = 'sptk';

class FetchingMenu : public BPopUpMenu {
public:
	FetchingMenu() : BPopUpMenu("relations", false, false), fItem(NULL), fRunner(NULL), fPending(false) {}
	~FetchingMenu() { delete fRunner; }

	// as BSlowMenu does it: asked when the menu is attached, and the menu is not shown before this has returned
	virtual bool AddDynamicItem(add_state state)
	{
		if (state != B_INITIAL_ADD || fPending || CountItems() > 0)
			return false;
		fPending = true;
		fItem = new SpinnerMenuItem("Fetching relations" B_UTF8_ELLIPSIS);
		fItem->SetEnabled(false);
		AddItem(fItem);
		fItem->StartSpinning();
		BMessenger self(this);
		BMessage tick(kTick);
		fRunner = new BMessageRunner(self, &tick, 80000);
		std::thread([self]() mutable {
			snooze(3000000);		// (the navigator works)
			self.SendMessage(kFetched);
		}).detach();
		return false;
	}

	virtual void MessageReceived(BMessage* message)
	{
		if (message->what == kTick) {
			if (fPending && fItem != NULL)
				fItem->NextFrame();
			return;
		}
		if (message->what == kFetched && fPending) {
			fPending = false;
			delete fRunner;
			fRunner = NULL;
			fItem->StopSpinning();
			RemoveItem(fItem);
			delete fItem;
			fItem = NULL;
			for (const char* name : {"Stephansdom", "Karlskirche", "Hofburg", "Schloss Schönbrunn", "Belvedere"})
				AddItem(new BMenuItem(name, NULL));
			InvalidateLayout();
			return;
		}
		BPopUpMenu::MessageReceived(message);
	}

private:
	SpinnerMenuItem*	fItem;
	BMessageRunner*		fRunner;
	bool				fPending;
};

int
main(int argc, char** argv)
{
	BApplication app("application/x-vnd.sen-labs.spinner-test");
	FetchingMenu* menu = new FetchingMenu();
	menu->Go(BPoint(300, 300), false, true, true);

	for (int frame = 0; frame < 70; frame++) {
		snooze(80000);
		if (frame == 12 || frame == 14 || frame == 60)
			system((BString("screenshot -s -f png /tmp/spinner-") << (frame == 12 ? 1 : frame == 14 ? 2 : 3) << ".png").String());
	}
	return 0;
}
