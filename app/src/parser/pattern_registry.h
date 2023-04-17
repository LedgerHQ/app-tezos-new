/* Tezos Embedded C parser for Ledger - Registry of contract names and entrypoint patterns

   Copyright 2023 Nomadic Labs <contact@nomadic-labs.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License. */

#pragma once

#include "parser_state.h"

bool find_pattern(uint8_t* address, char* entrypoint, const uint8_t** pattern, uint16_t* length);
bool find_name(uint8_t* address, const char** name);
