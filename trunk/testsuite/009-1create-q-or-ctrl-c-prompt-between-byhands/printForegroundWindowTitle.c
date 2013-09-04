#include <stdio.h>
#include <windows.h>
void main() {
	char title[1024];
	GetWindowText(GetForegroundWindow(), title, 1024);
	printf("%s\n", title);
}
