/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2026 SEN Labs e.U.
 */

/**
 * Asks the running Akita to open a relation view, as the SEN server does when a classification is chosen in its menu (sen::cmd::kOpenRelationsOfType), without a menu:
 *
 *   openrel <file>                  the folder of all the relation types of the file ("Open related...")
 *   openrel <file> <relation type>  the folder of the relations of one type, e.g. relation/x-vnd.sen-labs.relation.spatial.within
 *   openrel --all <file>            the folder of all the relations of the file in one ("All relations of ...", sen::cmd::kOpenAllRelationsView)
 *
 * Prints the reply of Akita (result 0 is ok). The views are folders below /tmp/sen/<view id>/. Build: g++ -std=c++20 -Wno-multichar -o openrel openrel.cpp -lbe
 */
#include <Application.h>
#include <Entry.h>
#include <Message.h>
#include <Messenger.h>

#include <stdio.h>
#include <string.h>

#include <sen/Sen.h>
#include <sen/SenMessages.h>

int
main(int argc, char** argv)
{
	BApplication app("application/x-vnd.sen-labs.openreltest");
	BMessenger tracker("application/x-vnd.Be-TRAK");
	bool all = argc > 1 && strcmp(argv[1], "--all") == 0;
	const char* path = argc > (all ? 2 : 1) ? argv[all ? 2 : 1] : NULL;
	if (!tracker.IsValid() || path == NULL) {
		fprintf(stderr, "usage: openrel [--all] <file> [<relation type>]\n(Akita must be running)\n");
		return 1;
	}
	entry_ref ref;
	if (get_ref_for_path(path, &ref) != B_OK) {
		fprintf(stderr, "%s: no such file\n", path);
		return 1;
	}

	BMessage message(all ? sen::cmd::kOpenAllRelationsView : sen::cmd::kOpenRelationsOfType);
	message.AddRef(sen::key::kSourceRef, &ref);
	if (!all && argc > 2)
		message.AddString(sen::key::kRelationType, argv[2]);
	if (all) {
		// (the view of all the relations is opened without an answer)
		status_t result = tracker.SendMessage(&message);
		printf("send: %s\n", strerror(result));
		return result == B_OK ? 0 : 1;
	}
	BMessage reply;
	status_t result = tracker.SendMessage(&message, &reply, 60000000, 60000000);
	printf("send: %s\n", strerror(result));
	reply.PrintToStream();
	return result == B_OK ? 0 : 1;
}
