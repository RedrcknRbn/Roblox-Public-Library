local Nexus = require("NexusUnitTesting")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Checkers = ReplicatedStorage.Checkers
local BoardParser = require(Checkers.BoardParser)
local Board = require(Checkers.Board)

local start = [[
.b.b.b.b
b.b.b.b.
.b.b.b.b
........
........
r.r.r.r.
.r.r.r.r
r.r.r.r.
]]
local startBoard = Board.new()
Nexus:RegisterUnitTest("Board.new", function(t)
	t:AssertEquals(start, BoardParser.ToString(startBoard), "ToString of Parse equals original")
end)

local Move = Board.Move
local v2 = Vector2.new
-- local argsReceived = {}
-- local function testMoves(...) -- collects arguments to eventually be sent to testTryMoves and testGetValidMoves for organization
-- 	argsReceived[#argsReceived + 1] = {...}
-- end
local tryMoveTest = Nexus.UnitTest.new("Board:TryMove()")
local getValidTest = Nexus.UnitTest.new("Board:GetValidMoves()")

local function listToString(list)
	local t = {}
	for i, coord in ipairs(list) do
		t[i] = tostring(coord)
	end
	return table.concat(t, "; ")
end
local coordListToKey = listToString
local function testMoves(case, board, team, start, valid, invalid, validBoardResults)
	tryMoveTest:RegisterUnitTest(case, function(test)
		for name, pos in pairs(valid) do
			local board = board:Clone()
			local move = Move.new(start, typeof(pos) == "Vector2" and {pos} or pos)
			local result = board:TryMove(team, move)
			local success = test:AssertEquals(true, not not result, name .. " - should be legal")
			if success and validBoardResults and validBoardResults[name] then
				local expectedBoard = BoardParser.Parse(validBoardResults[name])
				local allSame = true
				for x = 1, 8 do
					for y = 1, 8 do
						local pos = v2(x, y)
						if board:Get(pos) ~= expectedBoard:Get(pos) then
							allSame = false
							break
						end
					end
					if not allSame then break end
				end
				if not test:AssertEquals(true, allSame, name .. " - expected board not the same") then
					print("Resulting board:")
					print(BoardParser.ToString(board))
					print("Expected board:")
					print(BoardParser.ToString(expectedBoard))
				end
			end
		end
		for name, pos in pairs(invalid) do
			local board = board:Clone()
			local move = Move.new(start, typeof(pos) == "Vector2" and {pos} or pos)
			test:AssertEquals(false, not not board:TryMove(team, move), name .. " - should be illegal")
		end
	end)
	getValidTest:RegisterUnitTest(case, function(test)
		local unFound = {} -- Dictionary<coordList keys, true>
		for name, pos in pairs(valid) do
			unFound[coordListToKey(typeof(pos) == "Vector2" and {pos} or pos)] = true
		end
		local alreadyFound = {}
		for _, move in ipairs(board:GetValidMoves(team, start)) do
			local key = coordListToKey(move.coords)
			if unFound[key] then
				unFound[key] = nil
				alreadyFound[key] = true
			elseif alreadyFound[key] then
				test:Fail("GetValidMoves has duplicate move " .. listToString(unpack(move.coords)))
			else
				test:Fail("GetValidMoves has incorrect move " .. listToString(unpack(move.coords)))
			end
		end
		test:AssertEquals(next(unFound), nil, "GetValidMoves missed valid moves")
	end)
end

-- local function testTryMoves(case, board, team, start, valid, invalid, validBoardResults)
-- 	--	valid/invalid keys are descriptions and values are either position to move to or the list of positions to jump to
-- 	--	validBoardResults may have the same key for each valid test and its value should be a board string
-- 	test:Case(case)(function()
-- 		for name, pos in pairs(valid) do
-- 			local board = board:Clone()
-- 			local move = Move.new(start, typeof(pos) == "Vector2" and {pos} or pos)
-- 			local result = board:TryMove(team, move)
-- 			local success = test:Equals(not not result, true, name, "- should be legal")
-- 			if success and validBoardResults and validBoardResults[name] then
-- 				local expectedBoard = BoardParser.Parse(validBoardResults[name])
-- 				local allSame = true
-- 				for x = 1, 8 do
-- 					for y = 1, 8 do
-- 						local pos = v2(x, y)
-- 						if board:Get(pos) ~= expectedBoard:Get(pos) then
-- 							allSame = false
-- 							break
-- 						end
-- 					end
-- 					if not allSame then break end
-- 				end
-- 				if not test:Equals(allSame, true, name, "- expected board not the same") then
-- 					print("Resulting board:")
-- 					print(BoardParser.ToString(board))
-- 					print("Expected board:")
-- 					print(BoardParser.ToString(expectedBoard))
-- 				end
-- 			end
-- 		end
-- 		for name, pos in pairs(invalid) do
-- 			local board = board:Clone()
-- 			local move = Move.new(start, typeof(pos) == "Vector2" and {pos} or pos)
-- 			test:Equals(not not board:TryMove(team, move), false, name, "- should be illegal")
-- 		end
-- 	end)
-- end
-- local function testGetValidMoves(case, board, team, start, valid, invalid)
-- 	test:Case(case)(function()
-- 		local unFound = {} -- Dictionary<coordList keys, true>
-- 		for name, pos in pairs(valid) do
-- 			unFound[coordListToKey(typeof(pos) == "Vector2" and {pos} or pos)] = true
-- 		end
-- 		local alreadyFound = {}
-- 		for _, move in ipairs(board:GetValidMoves(team, start)) do
-- 			local key = coordListToKey(move.coords)
-- 			if unFound[key] then
-- 				unFound[key] = nil
-- 				alreadyFound[key] = true
-- 			elseif alreadyFound[key] then
-- 				test:Equals(false, true, "GetValidMoves has duplicate move", unpack(move.coords))
-- 			else
-- 				test:Equals(false, true, "GetValidMoves has incorrect move", unpack(move.coords))
-- 			end
-- 		end
-- 		test:Equals(next(unFound), nil, "GetValidMoves missed valid moves")
-- 	end)
-- end

local start_normal = [[
.b.b.b.b
b.b.b.b.
.b.b.b.b
........
.r......
..r.r.r.
.r.r.r.r
r.r.r.r.
]]
testMoves("start", startBoard, "Red", v2(1,6),
	{normal=v2(2,5)},
	{straightUp=v2(1,5), farRight=v2(4,5), upRightJumpOverNothing=v2(3,3)},
	{normal=start_normal})
testMoves("no moves", startBoard, "Red", v2(2,7),
	{},
	{onOwnPiece=v2(1,6), jumpOverOwnPiece=v2(4,5)})

local twoPiecesText = [[
........
........
.......B
........
.....r..
........
........
........
]] -- r is at 6,5; b is at 8,3
local twoPieces = BoardParser.Parse(twoPiecesText)

testMoves("pawn in middle", twoPieces, "Red", v2(6,5),
	{upLeft=v2(5,4), upRight=v2(7,4)},
	{cannotMoveBackwardsLeft=v2(5,6), cannotMoveBackwardsRight=v2(7,6)})

-- Make sure kings can go backwards/forwards
testMoves("king on side", twoPieces, "Black", v2(8,3),
	{kingUpLeft=v2(7,2), kingDownLeft=v2(7,4)},
	{upRightOffBoard=v2(2,1)})

-- Make sure pawns cannot move backwards even if board starts with red on top
local twoPiecesReverse = BoardParser.Parse(twoPiecesText, true) -- red starts on top
testMoves("red on top: pawn in middle", twoPiecesReverse, "Red", v2(6,5),
	{downLeft=v2(5,6), downRight=v2(7,6)},
	{cannotMoveBackwardsUpLeft=v2(5,4), cannotMoveBackwardsUpRight=v2(7,4)})

local captureBoard = BoardParser.Parse[[
.b.b.b.b
..r.r...
........
..r...b.
.....r..
r.r.r...
.r.r.B.r
r.r.....
]]

local captureBoard_capture8_3 = [[
.b.b.b.b
..r.r...
.......r
..r.....
........
r.r.r...
.r.r.B.r
r.r.....
]]
testMoves("pawn can capture", captureBoard, "Red", v2(6, 5),
	{jump=v2(8,3)},
	{cannotIgnoreCapture=v2(5,4)},
	{jump=captureBoard_capture8_3})
testMoves("cannot ignore other pawn capture", captureBoard, "Red", v2(1, 6),
	{},
	{cannotMove=v2(2,5)})
local captureBoard_doubleJump = [[
...b.b.b
....r...
........
......b.
.b...r..
r.r.r...
.r.r.B.r
r.r.....
]]
testMoves("pawn can jump when multiple pawns can capture", captureBoard, "Black", v2(2, 1),
	{doubleJump={v2(4,3), v2(2,5)}},
	{ignoreDoubleJump=v2(4,3), ignoreJump=v2(1,2)},
	{doubleJump = captureBoard_doubleJump})
testMoves("pawn can capture when multiple options", captureBoard, "Black", v2(4, 1),
	{singleJump=v2(6,3), doubleJump={v2(2,3),v2(4,5)}},
	{cannotIgnoreDoubleJump=v2(5,4)})
testMoves("pawn can't capture backwards", captureBoard, "Red", v2(5, 6),
	{},
	{cannotJumpBackwards=v2(7,8)})
local captureBoard_kingJump = [[
.b.b.b.b
..r.r...
.B......
......b.
.....r..
r.r.....
.r.r...r
r.r.....
]]
testMoves("king can capture backwards", captureBoard, "Black", v2(6, 7),
	{kingCaptureBackwards={v2(4,5), v2(2,3)}},
	{kingCannotIgnoreCapture_Backwards=v2(7,6), kingCannotIgnoreCapture_Forwards=v2(7,8)},
	{kingCaptureBackwards=captureBoard_kingJump})

local promotionBoard = BoardParser.Parse[[
........
..r.....
.....b..
........
........
b.......
.r.r....
........
]]
local promotionBoard_promoteR = [[
...R....
........
.....b..
........
........
b.......
.r.r....
........
]]
testMoves("promote pawn", promotionBoard, "Red", v2(3, 2),
	{moveAndPromote=v2(4,1), moveAndPromoteOther=v2(2,1)},
	{up=v2(3,1)},
	{moveAndPromote=promotionBoard_promoteR})
local promotionBoard_promoteB = [[
........
..r.....
.....b..
........
........
........
...r....
..B.....
]]
testMoves("promote while jump", promotionBoard, "Black", v2(1,6),
	{jumpAndStop=v2(3,8)},
	{cannotJumpAfterPromote={v2(3,8),v2(5,6)}},
	{jumpAndStop=promotionBoard_promoteB})

-- Actually run the tests
Nexus:RegisterUnitTest(tryMoveTest)
Nexus:RegisterUnitTest(getValidTest)

-- test:Set"Board:TryMove()"(function()
-- 	for _, args in ipairs(argsReceived) do
-- 		testTryMoves(unpack(args))
-- 	end
-- end)
-- test:Set"Board:GetValidMoves()"(function()
-- 	for _, args in ipairs(argsReceived) do
-- 		testGetValidMoves(unpack(args))
-- 	end
-- end)
-- return test:Finish()
return true