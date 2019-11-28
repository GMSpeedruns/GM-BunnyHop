#include "GarrysMod/Lua/Interface.h"
#include <stdio.h>
#include "interface.h"
#include "icvar.h"
#include "convar.h"

using namespace GarrysMod::Lua;

ICvar* convarHandle = NULL;
lua_State* lastState = NULL;

int ConCommandRemove( lua_State *state )
{
	LUA->CheckType(1, Type::STRING);

	const char* command = LUA->GetString(1);
	if (convarHandle->FindCommand(command)) {
		convarHandle->UnregisterConCommand(cvar->FindCommandBase(command));
		LUA->PushBool(true);
	}
	else
	{
		LUA->PushBool(false);
	}
	return 1;
}

void ConCommandTest(const CCommand &args)
{
	char dbuff[256];
	sprintf_s(dbuff, "[GAC] Test concommand");
	lastState->luabase->PushString(dbuff);
	lastState->luabase->Call(1, 0);
	lastState->luabase->Pop();
}
ConCommand concommand_test("test_concommand", ConCommandTest, "Test ConCommand through C++", FCVAR_NONE);

//
// Called when you module is opened
//
GMOD_MODULE_OPEN()
{
	lastState = state;

	LUA->PushSpecial(SPECIAL_GLOB);
	LUA->GetField(-1, "print");
	
	char dbuff[256];
	sprintf_s(dbuff, "[GAC] Module initialized");
	LUA->PushString(dbuff);
	LUA->Call(1, 0);
	LUA->Pop();

	CreateInterfaceFn VSTDLibFactory = Sys_GetFactory("vstdlib.dll");
	convarHandle = (ICvar*)VSTDLibFactory(CVAR_INTERFACE_VERSION, NULL);
	convarHandle->RegisterConCommand(&concommand_test);

	LUA->PushSpecial(SPECIAL_GLOB);
	LUA->GetField(-1, "engine");

	LUA->PushCFunction(ConCommandRemove);
	LUA->SetField(-2, "UnregisterConCommand");

	LUA->Pop();
	LUA->Pop();

	return 0;
}

//
// Called when your module is closed
//
GMOD_MODULE_CLOSE()
{
	convarHandle->UnregisterConCommand(&concommand_test);

	return 0;
}