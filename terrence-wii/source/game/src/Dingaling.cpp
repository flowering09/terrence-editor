#include "Dingaling.h"

#include <memory>
#include <string>

using namespace std::string_literals;

Dingaling::Dingaling():
	Thing(), _order_id(generate_order_id())
{

}

void Dingaling::init() {
	Thing::init();
}

void Dingaling::update(double dt) {
	Thing::update(dt);
}

void Dingaling::draw() {
	Thing::draw();
	StaticEngine::print("TERRENC"s);
}
