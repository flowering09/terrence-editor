#pragma once

#include "terrence.h"
#include <map>
#include <string>

struct SceneDefinition {
    const char* name;
    void (*build)(Thing* root);
};

static void build_template(Thing* root)
{
    Thing* Template = root;

    Thing3D* Root3D = dynamic_cast<Thing3D*>(ThingFactory::create("Thing3D"));
    Root3D->setPosition(0.000000f, 0.000000f, 0.000000f);
    Template->addChild(Root3D);
    Thing2D* Root2D = dynamic_cast<Thing2D*>(ThingFactory::create("Thing2D"));
    Root2D->setPosition(0.000000f, 0.000000f);
    Template->addChild(Root2D);
    Thing2D* RootUI = dynamic_cast<Thing2D*>(ThingFactory::create("Thing2D"));
    RootUI->setPosition(0.000000f, 0.000000f);
    Template->addChild(RootUI);
}

static void build_scene(Thing* root)
{
    Thing* Scene = root;

    Thing3D* Root3D = dynamic_cast<Thing3D*>(ThingFactory::create("Thing3D"));
    Root3D->setPosition(0.000000f, 0.000000f, 0.000000f);
    Scene->addChild(Root3D);
    AnimatedMesh* Terrence = dynamic_cast<AnimatedMesh*>(ThingFactory::create("AnimatedMesh"));
    Terrence->setPosition(0.000000f, 0.000000f, 0.000000f);

	    Loadable Terrence_load;
	    Terrence_load.animatedMesh = &a_animation;
	    Terrence->load(Terrence_load);
	    Root3D->addChild(Terrence);
    AnimatedMesh* Livio = dynamic_cast<AnimatedMesh*>(ThingFactory::create("AnimatedMesh"));
    Livio->setPosition(3.315793f, -0.969242f, 0.000000f);

	    Loadable Livio_load;
	    Livio_load.animatedMesh = &koryfosi_animation;
	    Livio->load(Livio_load);
	    Root3D->addChild(Livio);
    DebugCamera* ScriptedThing = dynamic_cast<DebugCamera*>(ThingFactory::create("DebugCamera"));
    Root3D->addChild(ScriptedThing);
    Thing2D* Root2D = dynamic_cast<Thing2D*>(ThingFactory::create("Thing2D"));
    Root2D->setPosition(0.000000f, 0.000000f);
    Scene->addChild(Root2D);
    Thing2D* RootUI = dynamic_cast<Thing2D*>(ThingFactory::create("Thing2D"));
    RootUI->setPosition(0.000000f, 0.000000f);
    Scene->addChild(RootUI);
    Dingaling* ScriptedThing2 = dynamic_cast<Dingaling*>(ThingFactory::create("Dingaling"));
    RootUI->addChild(ScriptedThing2);
}

static std::map<std::string, SceneDefinition> scenes = {
    { "Template", { "Template", build_template } },
    { "Scene", { "Scene", build_scene } },
};
