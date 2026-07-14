#pragma once

#include <memory>
#include "_HaxeUtils.h"

class Dingaling: public Thing {
public:
	Dingaling();
	void init() override;
	void update(double dt) override;
	void draw() override;

	HX_COMPARISON_OPERATORS(Dingaling)
};

