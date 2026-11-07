/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2026 SEN Labs e.U.
 */

/**
 * Launches an application with files as refs (B_REFS_RECEIVED), as Akita does for the click on a target in the menu of a relation: the application of the relation type gets the target itself.
 *
 *   launchrefs <application signature> <file>...
 *
 * Build: g++ -std=c++20 -Wno-multichar -o launchrefs launchrefs.cpp -lbe
 */
#include <Application.h>
#include <Entry.h>
#include <Message.h>
#include <Roster.h>

#include <stdio.h>

int
main(int argc, char** argv)
{
	if (argc < 3) {
		fprintf(stderr, "usage: launchrefs <application signature> <file>...\n");
		return 1;
	}
	BApplication app("application/x-vnd.sen-labs.launchrefstest");
	BMessage refs(B_REFS_RECEIVED);
	for (int index = 2; index < argc; index++) {
		entry_ref ref;
		if (get_ref_for_path(argv[index], &ref) != B_OK) {
			fprintf(stderr, "%s: no such file\n", argv[index]);
			return 1;
		}
		refs.AddRef("refs", &ref);
	}
	status_t result = be_roster->Launch(argv[1], &refs);
	printf("launch: %s\n", strerror(result));
	return result == B_OK || result == B_ALREADY_RUNNING ? 0 : 1;
}
