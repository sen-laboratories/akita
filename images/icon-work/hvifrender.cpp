// hvifrender <file.hvif> <out prefix> : renders the icon with the vector icon renderer of Haiku (it honours the level of detail) at 16, 32, 48, 64 and 128
#include <Application.h>
#include <Bitmap.h>
#include <BitmapStream.h>
#include <File.h>
#include <IconUtils.h>
#include <TranslatorRoster.h>
#include <stdio.h>
#include <string.h>
#include <vector>
int main(int, char** argv)
{
	BApplication app("application/x-vnd.sen-test-hvifrender");
	BFile file(argv[1], B_READ_ONLY);
	off_t size = 0; file.GetSize(&size);
	std::vector<uint8> data((size_t)size);
	file.Read(data.data(), (size_t)size);
	const int sizes[] = {16, 32, 48, 64, 128};
	for (int s : sizes) {
		BBitmap bitmap(BRect(0, 0, s - 1, s - 1), B_RGBA32);
		memset(bitmap.Bits(), 0, bitmap.BitsLength());
		status_t r = BIconUtils::GetVectorIcon(data.data(), data.size(), &bitmap);
		char name[256]; snprintf(name, sizeof(name), "%s_%d.png", argv[2], s);
		BFile out(name, B_WRITE_ONLY | B_CREATE_FILE | B_ERASE_FILE);
		BBitmapStream stream(&bitmap);
		BTranslatorRoster::Default()->Translate(&stream, NULL, NULL, &out, B_PNG_FORMAT);
		BBitmap* back; stream.DetachBitmap(&back);
		printf("%d: %s\n", s, strerror(r));
	}
	return 0;
}
