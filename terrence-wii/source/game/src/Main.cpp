#include "Main.h"

#include <memory>
#include "Dingaling.h"

void Main::main() {
	static_cast<void>(std::make_shared<Dingaling>());
}
