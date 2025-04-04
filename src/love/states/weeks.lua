--[[----------------------------------------------------------------------------
This file is part of Friday Night Funkin' Rewritten

Copyright (C) 2021  HTV04

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
------------------------------------------------------------------------------]]

local animList = {
	"left",
	"down",
	"up",
	"right"
}
local inputList = {
	"gameLeft",
	"gameDown",
	"gameUp",
	"gameRight"
}

local ratingTimers = {}

local useAltAnims
local notMissed = {}

return {
	enter = function(self)
		sounds = {
			countdown = {
				three = love.audio.newSource("sounds/countdown-3.ogg", "static"),
				two = love.audio.newSource("sounds/countdown-2.ogg", "static"),
				one = love.audio.newSource("sounds/countdown-1.ogg", "static"),
				go = love.audio.newSource("sounds/countdown-go.ogg", "static")
			},
			miss = {
				love.audio.newSource("sounds/miss1.ogg", "static"),
				love.audio.newSource("sounds/miss2.ogg", "static"),
				love.audio.newSource("sounds/miss3.ogg", "static")
			},
			breath = love.audio.newSource("sounds/exhale.ogg", "static"),
			death = love.audio.newSource("sounds/death.ogg", "static")
		}

		images = {
			icons = love.graphics.newImage(graphics.imagePath("icons")),
			notes = love.graphics.newImage(graphics.imagePath("notes")),
			numbers = love.graphics.newImage(graphics.imagePath("numbers"))
		}

		sprites = {
			icons = love.filesystem.load("sprites/icons.lua"),
			numbers = love.filesystem.load("sprites/numbers.lua")
		}

		girlfriend = love.filesystem.load("sprites/girlfriend.lua")()
		boyfriend = love.filesystem.load("sprites/boyfriend.lua")()

		rating = love.filesystem.load("sprites/rating.lua")()

		rating.sizeX, rating.sizeY = 0.75, 0.75
		numbers = {}
		for i = 1, 3 do
			numbers[i] = sprites.numbers()

			numbers[i].sizeX, numbers[i].sizeY = 0.5, 0.5
		end

		enemyIcon = sprites.icons()
		boyfriendIcon = sprites.icons()

		if settings.downscroll then
			enemyIcon.y = -400
			boyfriendIcon.y = -400
		else
			enemyIcon.y = 350
			boyfriendIcon.y = 350
		end
		enemyIcon.sizeX, enemyIcon.sizeY = 1.5, 1.5
		boyfriendIcon.sizeX, boyfriendIcon.sizeY = -1.5, 1.5

		countdownFade = {}
		countdown = love.filesystem.load("sprites/countdown.lua")()
	end,

	load = function(self)
		for i = 1, 4 do
			notMissed[i] = true
		end
		useAltAnims = false
		if not pixelTime then
			cam.x, cam.y = -boyfriend.x + 100, -boyfriend.y + 75
		elseif pixelTime then
			cam.x, cam.y = -boyfriend.x + 30, -boyfriend.y + 25
		end
		rating.x = girlfriend.x
		for i = 1, 3 do
			numbers[i].x = girlfriend.x - 100 + 50 * i
		end

		ratingVisibility = {0}
		combo = 0

		enemy:animate("idle")
		boyfriend:animate("idle")

		graphics.fadeIn(0.5)
	end,

	initUI = function(self)
		events = {}
		enemyNotes = {}
		boyfriendNotes = {}
		health = 50
		score = 0

		sprites.leftArrow = love.filesystem.load("sprites/left-arrow.lua")
		sprites.downArrow = love.filesystem.load("sprites/down-arrow.lua")
		sprites.upArrow = love.filesystem.load("sprites/up-arrow.lua")
		sprites.rightArrow = love.filesystem.load("sprites/right-arrow.lua")

		sprites.leftArrow2 = love.filesystem.load("sprites/pixel/left-arrow.lua")
		sprites.downArrow2 = love.filesystem.load("sprites/pixel/down-arrow.lua")
		sprites.upArrow2 = love.filesystem.load("sprites/pixel/up-arrow.lua")
		sprites.rightArrow2 = love.filesystem.load("sprites/pixel/right-arrow.lua")

		enemyArrows = {
			sprites.leftArrow(),
			sprites.downArrow(),
			sprites.upArrow(),
			sprites.rightArrow()
		}
		boyfriendArrows= {
			sprites.leftArrow(),
			sprites.downArrow(),
			sprites.upArrow(),
			sprites.rightArrow()
		}
		enemyArrows2 = {
			sprites.leftArrow2(),
			sprites.downArrow2(),
			sprites.upArrow2(),
			sprites.rightArrow2()
		}
		boyfriendArrows2 = {
			sprites.leftArrow2(),
			sprites.downArrow2(),
			sprites.upArrow2(),
			sprites.rightArrow2()
		}

		for i = 1, 4 do
			if not pixelTime then
				enemyArrows[i].x = -925 + 165 * i
				boyfriendArrows[i].x = 100 + 165 * i
				if settings.downscroll then
					enemyArrows[i].y = 400
					boyfriendArrows[i].y = 400
				else
					enemyArrows[i].y = -400
					boyfriendArrows[i].y = -400
				end

				enemyNotes[i] = {}
				boyfriendNotes[i] = {}
			elseif pixelTime then
				enemyArrows[i].x = -125 + 20 * i
				boyfriendArrows[i].x = 25 + 20 * i
				if settings.downscroll then
					enemyArrows[i].y = 55
					boyfriendArrows[i].y = 55
				else
					enemyArrows[i].y = -55
					boyfriendArrows[i].y = -55
				end

				enemyNotes[i] = {}
				boyfriendNotes[i] = {}
			end
		end
	end,

	generateNotes = function(self, chart)
		local eventBpm

		for i = 1, #chart do
			bpm = chart[i].bpm

			if bpm then
				break
			end
		end
		if not bpm then
			bpm = 100
		end

		speed = chart.speed
		if not pixelTime then
			for i = 1, #chart do
				eventBpm = chart[i].bpm

				for j = 1, #chart[i].sectionNotes do
					local sprite

					local mustHitSection = chart[i].mustHitSection
					local altAnim = chart[i].altAnim
					local noteType = chart[i].sectionNotes[j].noteType
					local noteTime = chart[i].sectionNotes[j].noteTime

					if j == 1 then
						table.insert(events, {eventTime = chart[i].sectionNotes[1].noteTime, mustHitSection = mustHitSection, bpm = eventBpm, altAnim = altAnim})
					end

					if noteType == 0 or noteType == 4 then
						sprite = sprites.leftArrow
					elseif noteType == 1 or noteType == 5 then
						sprite = sprites.downArrow
					elseif noteType == 2 or noteType == 6 then
						sprite = sprites.upArrow
					elseif noteType == 3 or noteType == 7 then
						sprite = sprites.rightArrow
					end

					if settings.downscroll then
						if mustHitSection then
							if noteType >= 4 then
								local id = noteType - 3
								local c = #enemyNotes[id] + 1
								local x = enemyArrows[id].x

								table.insert(enemyNotes[id], sprite())
								enemyNotes[id][c].x = x
								enemyNotes[id][c].y = 400 - noteTime * 0.6 * speed

								enemyNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #enemyNotes[id] + 1

										table.insert(enemyNotes[id], sprite())
										enemyNotes[id][c].x = x
										enemyNotes[id][c].y = 400 - (noteTime + k) * 0.6 * speed

										enemyNotes[id][c]:animate("hold", false)
									end

									c = #enemyNotes[id]

									enemyNotes[id][c].offsetY = -10
									enemyNotes[id][c].sizeY = -1

									enemyNotes[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #boyfriendNotes[id] + 1
								local x = boyfriendArrows[id].x

								table.insert(boyfriendNotes[id], sprite())
								boyfriendNotes[id][c].x = x
								boyfriendNotes[id][c].y = 400 - noteTime * 0.6 * speed

								boyfriendNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #boyfriendNotes[id] + 1

										table.insert(boyfriendNotes[id], sprite())
										boyfriendNotes[id][c].x = x
										boyfriendNotes[id][c].y = 400 - (noteTime + k) * 0.6 * speed

										boyfriendNotes[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes[id]

									boyfriendNotes[id][c].offsetY = -10
									boyfriendNotes[id][c].sizeY = -1

									boyfriendNotes[id][c]:animate("end", false)
								end
							end
						else
							if noteType >= 4 then
								local id = noteType - 3
								local c = #boyfriendNotes[id] + 1
								local x = boyfriendArrows[id].x

								table.insert(boyfriendNotes[id], sprite())
								boyfriendNotes[id][c].x = x
								boyfriendNotes[id][c].y = 400 - noteTime * 0.6 * speed

								boyfriendNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #boyfriendNotes[id] + 1

										table.insert(boyfriendNotes[id], sprite())
										boyfriendNotes[id][c].x = x
										boyfriendNotes[id][c].y = 400 - (noteTime + k) * 0.6 * speed

										boyfriendNotes[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes[id]

									boyfriendNotes[id][c].offsetY = -10
									boyfriendNotes[id][c].sizeY = -1

									boyfriendNotes[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #enemyNotes[id] + 1
								local x = enemyArrows[id].x

								table.insert(enemyNotes[id], sprite())
								enemyNotes[id][c].x = x
								enemyNotes[id][c].y = 400 - noteTime * 0.6 * speed

								enemyNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #enemyNotes[id] + 1

										table.insert(enemyNotes[id], sprite())
										enemyNotes[id][c].x = x
										enemyNotes[id][c].y = 400 - (noteTime + k) * 0.6 * speed

										enemyNotes[id][c]:animate("hold", false)
									end

									c = #enemyNotes[id]

									enemyNotes[id][c].offsetY = -10
									enemyNotes[id][c].sizeY = -1

									enemyNotes[id][c]:animate("end", false)
								end
							end
						end
					else
						if mustHitSection then
							if noteType >= 4 then
								local id = noteType - 3
								local c = #enemyNotes[id] + 1
								local x = enemyArrows[id].x

								table.insert(enemyNotes[id], sprite())
								enemyNotes[id][c].x = x
								enemyNotes[id][c].y = -400 + noteTime * 0.6 * speed

								enemyNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #enemyNotes[id] + 1

										table.insert(enemyNotes[id], sprite())
										enemyNotes[id][c].x = x
										enemyNotes[id][c].y = -400 + (noteTime + k) * 0.6 * speed

										enemyNotes[id][c]:animate("hold", false)
									end

									c = #enemyNotes[id]

									enemyNotes[id][c].offsetY = -10

									enemyNotes[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #boyfriendNotes[id] + 1
								local x = boyfriendArrows[id].x

								table.insert(boyfriendNotes[id], sprite())
								boyfriendNotes[id][c].x = x
								boyfriendNotes[id][c].y = -400 + noteTime * 0.6 * speed

								boyfriendNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #boyfriendNotes[id] + 1

										table.insert(boyfriendNotes[id], sprite())
										boyfriendNotes[id][c].x = x
										boyfriendNotes[id][c].y = -400 + (noteTime + k) * 0.6 * speed

										boyfriendNotes[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes[id]

									boyfriendNotes[id][c].offsetY = -10

									boyfriendNotes[id][c]:animate("end", false)
								end
							end
						else
							if noteType >= 4 then
								local id = noteType - 3
								local c = #boyfriendNotes[id] + 1
								local x = boyfriendArrows[id].x

								table.insert(boyfriendNotes[id], sprite())
								boyfriendNotes[id][c].x = x
								boyfriendNotes[id][c].y = -400 + noteTime * 0.6 * speed

								boyfriendNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #boyfriendNotes[id] + 1

										table.insert(boyfriendNotes[id], sprite())
										boyfriendNotes[id][c].x = x
										boyfriendNotes[id][c].y = -400 + (noteTime + k) * 0.6 * speed

										boyfriendNotes[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes[id]

									boyfriendNotes[id][c].offsetY = -10

									boyfriendNotes[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #enemyNotes[id] + 1
								local x = enemyArrows[id].x

								table.insert(enemyNotes[id], sprite())
								enemyNotes[id][c].x = x
								enemyNotes[id][c].y = -400 + noteTime * 0.6 * speed

								enemyNotes[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 71 / speed, chart[i].sectionNotes[j].noteLength, 71 / speed do
										local c = #enemyNotes[id] + 1

										table.insert(enemyNotes[id], sprite())
										enemyNotes[id][c].x = x
										enemyNotes[id][c].y = -400 + (noteTime + k) * 0.6 * speed
										if k > chart[i].sectionNotes[j].noteLength - 71 / speed then
											enemyNotes[id][c].offsetY = -10

											enemyNotes[id][c]:animate("end", false)
										else
											enemyNotes[id][c]:animate("hold", false)
										end
									end

									c = #enemyNotes[id]

									enemyNotes[id][c].offsetY = -10

									enemyNotes[id][c]:animate("end", false)
								end
							end
						end
					end
				end
			end
		elseif pixelTime then
			for i = 1, #chart do
				eventBpm = chart[i].bpm

				for j = 1, #chart[i].sectionNotes do
					local sprite

					local mustHitSection = chart[i].mustHitSection
					local altAnim = chart[i].altAnim
					local noteType = chart[i].sectionNotes[j].noteType
					local noteTime = chart[i].sectionNotes[j].noteTime

					if j == 1 then
						table.insert(events, {eventTime = chart[i].sectionNotes[1].noteTime, mustHitSection = mustHitSection, bpm = eventBpm, altAnim = altAnim})
					end

					if noteType == 0 or noteType == 4 then
						sprite = sprites.leftArrow2
					elseif noteType == 1 or noteType == 5 then
						sprite = sprites.downArrow2
					elseif noteType == 2 or noteType == 6 then
						sprite = sprites.upArrow2
					elseif noteType == 3 or noteType == 7 then
						sprite = sprites.rightArrow2
					end

					if settings.downscroll then
						if mustHitSection then
							if noteType >= 4 then
								local id = noteType - 3
								local c = #enemyNotes2[id] + 1
								local x = enemyArrows2[id].x

								table.insert(enemyNotes2[id], sprite())
								enemyNotes2[id][c].x = x
								enemyNotes2[id][c].y = 55 - noteTime * 0.12 * speed

								enemyNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #enemyNotes2[id] + 1

										table.insert(enemyNotes2[id], sprite())
										enemyNotes2[id][c].x = x
										enemyNotes2[id][c].y = 55 - (noteTime + k) * 0.12 * speed

										enemyNotes2[id][c]:animate("hold", false)
									end

									c = #enemyNotes2[id]

									enemyNotes2[id][c].sizeY = -1

									enemyNotes2[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #boyfriendNotes2[id] + 1
								local x = boyfriendArrows2[id].x

								table.insert(boyfriendNotes2[id], sprite())
								boyfriendNotes2[id][c].x = x
								boyfriendNotes2[id][c].y = 55 - noteTime * 0.12 * speed

								boyfriendNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #boyfriendNotes2[id] + 1

										table.insert(boyfriendNotes2[id], sprite())
										boyfriendNotes2[id][c].x = x
										boyfriendNotes2[id][c].y = 55 - (noteTime + k) * 0.12 * speed

										boyfriendNotes2[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes2[id]

									boyfriendNotes2[id][c].sizeY = -1

									boyfriendNotes2[id][c]:animate("end", false)
								end
							end
						else
							if noteType >= 4 then
								local id = noteType - 3
								local c = #boyfriendNotes2[id] + 1
								local x = boyfriendArrows2[id].x

								table.insert(boyfriendNotes2[id], sprite())
								boyfriendNotes2[id][c].x = x
								boyfriendNotes2[id][c].y = 55 - noteTime * 0.12 * speed

								boyfriendNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #boyfriendNotes2[id] + 1

										table.insert(boyfriendNotes2[id], sprite())
										boyfriendNotes2[id][c].x = x
										boyfriendNotes2[id][c].y = 55 - (noteTime + k) * 0.12 * speed

										boyfriendNotes2[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes2[id]

									boyfriendNotes2[id][c].sizeY = -1

									boyfriendNotes2[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #enemyNotes2[id] + 1
								local x = enemyArrows2[id].x

								table.insert(enemyNotes2[id], sprite())
								enemyNotes2[id][c].x = x
								enemyNotes2[id][c].y = 55 - noteTime * 0.12 * speed

								enemyNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #enemyNotes2[id] + 1

										table.insert(enemyNotes2[id], sprite())
										enemyNotes2[id][c].x = x
										enemyNotes2[id][c].y = 55 - (noteTime + k) * 0.12 * speed

										enemyNotes2[id][c]:animate("hold", false)
									end

									c = #enemyNotes2[id]

									enemyNotes2[id][c].sizeY = -1

									enemyNotes2[id][c]:animate("end", false)
								end
							end
						end
					else
						if mustHitSection then
							if noteType >= 4 then
								local id = noteType - 3
								local c = #enemyNotes2[id] + 1
								local x = enemyArrows2[id].x

								table.insert(enemyNotes2[id], sprite())
								enemyNotes2[id][c].x = x
								enemyNotes2[id][c].y = -55 + noteTime * 0.12 * speed

								enemyNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #enemyNotes2[id] + 1

										table.insert(enemyNotes2[id], sprite())
										enemyNotes2[id][c].x = x
										enemyNotes2[id][c].y = -55 + (noteTime + k) * 0.12 * speed

										enemyNotes2[id][c]:animate("hold", false)
									end

									c = #enemyNotes2[id]

									enemyNotes2[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #boyfriendNotes2[id] + 1
								local x = boyfriendArrows2[id].x

								table.insert(boyfriendNotes2[id], sprite())
								boyfriendNotes2[id][c].x = x
								boyfriendNotes2[id][c].y = -55 + noteTime * 0.12 * speed

								boyfriendNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #boyfriendNotes2[id] + 1

										table.insert(boyfriendNotes2[id], sprite())
										boyfriendNotes2[id][c].x = x
										boyfriendNotes2[id][c].y = -55 + (noteTime + k) * 0.12 * speed

										boyfriendNotes2[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes2[id]

									boyfriendNotes2[id][c]:animate("end", false)
								end
							end
						else
							if noteType >= 4 then
								local id = noteType - 3
								local c = #boyfriendNotes2[id] + 1
								local x = boyfriendArrows2[id].x

								table.insert(boyfriendNotes2[id], sprite())
								boyfriendNotes2[id][c].x = x
								boyfriendNotes2[id][c].y = -55 + noteTime * 0.12 * speed

								boyfriendNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #boyfriendNotes2[id] + 1

										table.insert(boyfriendNotes2[id], sprite())
										boyfriendNotes2[id][c].x = x
										boyfriendNotes2[id][c].y = -55 + (noteTime + k) * 0.12 * speed

										boyfriendNotes2[id][c]:animate("hold", false)
									end

									c = #boyfriendNotes2[id]

									boyfriendNotes2[id][c]:animate("end", false)
								end
							else
								local id = noteType + 1
								local c = #enemyNotes2[id] + 1
								local x = enemyArrows2[id].x

								table.insert(enemyNotes2[id], sprite())
								enemyNotes2[id][c].x = x
								enemyNotes2[id][c].y = -55 + noteTime * 0.12 * speed

								enemyNotes2[id][c]:animate("on", false)

								if chart[i].sectionNotes[j].noteLength > 0 then
									local c

									for k = 42 / speed, chart[i].sectionNotes[j].noteLength, 42 / speed do
										local c = #enemyNotes2[id] + 1

										table.insert(enemyNotes2[id], sprite())
										enemyNotes2[id][c].x = x
										enemyNotes2[id][c].y = -55 + (noteTime + k) * 0.12 * speed

										enemyNotes2[id][c]:animate("hold", false)
									end

									c = #enemyNotes2[id]

									enemyNotes2[id][c]:animate("end", false)
								end
							end
						end
					end
				end
			end
		end
		if not pixelTime then
			if settings.downscroll then
				for i = 1, 4 do
					table.sort(enemyNotes[i], function(a, b) return a.y > b.y end)
					table.sort(boyfriendNotes[i], function(a, b) return a.y > b.y end)
				end
			else
				for i = 1, 4 do
					table.sort(enemyNotes[i], function(a, b) return a.y < b.y end)
					table.sort(boyfriendNotes[i], function(a, b) return a.y < b.y end)
				end
			end
		elseif pixelTime then
			if settings.downscroll then
				for i = 1, 4 do
					table.sort(enemyNotes2[i], function(a, b) return a.y > b.y end)
					table.sort(boyfriendNotes2[i], function(a, b) return a.y > b.y end)
				end
			else
				for i = 1, 4 do
					table.sort(enemyNotes2[i], function(a, b) return a.y < b.y end)
					table.sort(boyfriendNotes2[i], function(a, b) return a.y < b.y end)
				end
			end
		end
		if not pixelTime then
			-- Workarounds for bad charts that have multiple notes around the same place
			for i = 1, 4 do
				local offset = 0

				for j = 2, #enemyNotes[i] do
					local index = j - offset

					if enemyNotes[i][index]:getAnimName() == "on" and enemyNotes[i][index - 1]:getAnimName() == "on" and ((not settings.downscroll and enemyNotes[i][index].y - enemyNotes[i][index - 1].y <= 10) or (settings.downscroll and enemyNotes[i][index].y - enemyNotes[i][index - 1].y >= -10)) then
						table.remove(enemyNotes[i], index)

						offset = offset + 1
					end
				end
			end
			for i = 1, 4 do
				local offset = 0

				for j = 2, #boyfriendNotes[i] do
					local index = j - offset

					if boyfriendNotes[i][index]:getAnimName() == "on" and boyfriendNotes[i][index - 1]:getAnimName() == "on" and ((not settings.downscroll and boyfriendNotes[i][index].y - boyfriendNotes[i][index - 1].y <= 10) or (settings.downscroll and boyfriendNotes[i][index].y - boyfriendNotes[i][index - 1].y >= -10)) then
						table.remove(boyfriendNotes[i], index)

						offset = offset + 1
					end
				end
			end
		elseif pixelTime then
			-- Workarounds for bad charts that have multiple notes around the same place
			for i = 1, 4 do
				local offset = 0

				for j = 2, #enemyNotes2[i] do
					local index = j - offset

					if enemyNotes2[i][index]:getAnimName() == "on" and enemyNotes2[i][index - 1]:getAnimName() == "on" and ((not settings.downscroll and enemyNotes2[i][index].y - enemyNotes2[i][index - 1].y <= 2) or (settings.downscroll and enemyNotes2[i][index].y - enemyNotes2[i][index - 1].y >= -2)) then
						table.remove(enemyNotes2[i], index)

						offset = offset + 1
					end
				end
			end
			for i = 1, 4 do
				local offset = 0

				for j = 2, #boyfriendNotes[i] do
					local index = j - offset

					if boyfriendNotes2[i][index]:getAnimName() == "on" and boyfriendNotes2[i][index - 1]:getAnimName() == "on" and ((not settings.downscroll and boyfriendNotes2[i][index].y - boyfriendNotes2[i][index - 1].y <= 2) or (settings.downscroll and boyfriendNotes2[i][index].y - boyfriendNotes2[i][index - 1].y >= -2)) then
						table.remove(boyfriendNotes2[i], index)

						offset = offset + 1
					end
				end
			end
		end
	end,

	-- Gross countdown script
	setupCountdown = function(self)
		lastReportedPlaytime = 0
		musicTime = (240 / bpm) * -1000

		musicThres = 0
		musicPos = 0

		countingDown = true
		countdownFade[1] = 0
		audio.playSound(sounds.countdown.three)
		Timer.after(
			(60 / bpm),
			function()
				countdown:animate("ready")
				countdownFade[1] = 1
				audio.playSound(sounds.countdown.two)
				Timer.tween(
					(60 / bpm),
					countdownFade,
					{0},
					"linear",
					function()
						countdown:animate("set")
						countdownFade[1] = 1
						audio.playSound(sounds.countdown.one)
						Timer.tween(
							(60 / bpm),
							countdownFade,
							{0},
							"linear",
							function()
								countdown:animate("go")
								countdownFade[1] = 1
								audio.playSound(sounds.countdown.go)
								Timer.tween(
									(60 / bpm),
									countdownFade,
									{0},
									"linear",
									function()
										countingDown = false

										previousFrameTime = love.timer.getTime() * 1000
										musicTime = 0

										if inst then inst:play() end
										voices:play()
									end
								)
							end
						)
					end
				)
			end
		)
	end,

	safeAnimate = function(self, sprite, animName, loopAnim, timerID)
		sprite:animate(animName, loopAnim)

		spriteTimers[timerID] = 12
	end,

	update = function(self, dt)
		oldMusicThres = musicThres
		if countingDown or love.system.getOS() == "Web" then -- Source:tell() can't be trusted on love.js!
			musicTime = musicTime + 1000 * dt
		else
			if not graphics.isFading() then
				local time = love.timer.getTime()
				local seconds = voices:tell("seconds")

				musicTime = musicTime + (time * 1000) - previousFrameTime
				previousFrameTime = time * 1000

				if lastReportedPlaytime ~= seconds * 1000 then
					lastReportedPlaytime = seconds * 1000
					musicTime = (musicTime + lastReportedPlaytime) / 2
				end
			end
		end
		absMusicTime = math.abs(musicTime)
		musicThres = math.floor(absMusicTime / 100) -- Since "musicTime" isn't precise, this is needed
		if not pixelTime then
			for i = 1, #events do
				if events[i].eventTime <= absMusicTime then
					local oldBpm = bpm

					if events[i].bpm then
						bpm = events[i].bpm
						if not bpm then bpm = oldBpm end
					end

					if camTimer then
						Timer.cancel(camTimer)
					end
					if events[i].mustHitSection then
						camTimer = Timer.tween(1.25, cam, {x = -boyfriend.x + 100, y = -boyfriend.y + 75}, "out-quad")
					else
						camTimer = Timer.tween(1.25, cam, {x = -enemy.x - 100, y = -enemy.y + 75}, "out-quad")
					end

					if events[i].altAnim then
						useAltAnims = true
					else
						useAltAnims = false
					end

					table.remove(events, i)

					break
				end
			end
		elseif pixelTime then
			for i = 1, #events do
				if events[i].eventTime <= absMusicTime then
					local oldBpm = bpm
	
					if events[i].bpm then
						bpm = events[i].bpm
						if not bpm then bpm = oldBpm end
					end
	
					if camTimer then
						Timer.cancel(camTimer)
					end 
					if events[i].mustHitSection then
						camTimer = Timer.tween(1.25, cam, {x = -boyfriend.x + 30, y = -boyfriend.y + 25}, "out-quad")
					else
						camTimer = Timer.tween(1.25, cam, {x = -enemy.x - 30, y = -enemy.y + 5}, "out-quad")
					end
	
					if events[i].altAnim then
						useAltAnims = true
					else
						useAltAnims = false
					end
	
					table.remove(events, i)
	
					break
				end
			end
		end
		
		

		girlfriend:update(dt)
		enemy:update(dt)
		boyfriend:update(dt)

		if musicThres ~= oldMusicThres and math.fmod(absMusicTime, 120000 / bpm) < 100 then
			if spriteTimers[1] == 0 then
				girlfriend:animate("idle", false)

				girlfriend:setAnimSpeed(14.4 / (60 / bpm))
			end
			if spriteTimers[2] == 0 then
				if enemy:getAnimName() ~= "last" then
					self:safeAnimate(enemy, "idle", false, 2)
				end
			end
			if spriteTimers[3] == 0 then
				self:safeAnimate(boyfriend, "idle", false, 3)
			end
		end

		for i = 1, 3 do
			local spriteTimer = spriteTimers[i]

			if spriteTimer > 0 then
				spriteTimers[i] = spriteTimer - 1
			end
		end
	end,

	updateUI = function(self, dt)
		if not pixelTime then
			if settings.downscroll then
				musicPos = -musicTime * 0.6 * speed
			else
				musicPos = musicTime * 0.6 * speed
			end

			for i = 1, 4 do
				local enemyArrow = enemyArrows[i]
				local boyfriendArrow = boyfriendArrows[i]
				local enemyNote = enemyNotes[i]
				local boyfriendNote = boyfriendNotes[i]
				local curAnim = animList[i]
				local curInput = inputList[i]

				local noteNum = i

				enemyArrow:update(dt)
				boyfriendArrow:update(dt)

				if not enemyArrow:isAnimated() then
					enemyArrow:animate("off", false)
				end

				if #enemyNote > 0 then
					if (not settings.downscroll and enemyNote[1].y - musicPos <= -400) or (settings.downscroll and enemyNote[1].y - musicPos >= 400) then
						voices:setVolume(1)

						enemyArrow:animate("confirm", false)

						if enemyNote[1]:getAnimName() == "hold" or enemyNote[1]:getAnimName() == "end" then
							if useAltAnims then
								if (not enemy:isAnimated()) or enemy:getAnimName() == "idle" then self:safeAnimate(enemy, curAnim .. " alt", true, 2) end
							else
								if (not enemy:isAnimated()) or enemy:getAnimName() == "idle" then self:safeAnimate(enemy, curAnim, true, 2) end
							end
						else
							if useAltAnims then
								self:safeAnimate(enemy, curAnim .. " alt", false, 2)
							else
								self:safeAnimate(enemy, curAnim, false, 2)
							end
						end

						table.remove(enemyNote, 1)
					end
				end

				if #boyfriendNote > 0 then
					if (not settings.downscroll and boyfriendNote[1].y - musicPos < -500) or (settings.downscroll and boyfriendNote[1].y - musicPos > 500) then
						if inst then voices:setVolume(0) end

						notMissed[noteNum] = false

						table.remove(boyfriendNote, 1)

						if combo >= 5 then self:safeAnimate(girlfriend, "sad", true, 1) end

						combo = 0
						health = health - 2
					end
				end

				if input:pressed(curInput) then
					local success = false

					if settings.kadeInput then
						success = true
					end

					boyfriendArrow:animate("press", false)

					if #boyfriendNote > 0 then
						for i = 1, #boyfriendNote do
							if boyfriendNote[i] and boyfriendNote[i]:getAnimName() == "on" then
								if (not settings.downscroll and boyfriendNote[i].y - musicPos <= -280) or (settings.downscroll and boyfriendNote[i].y - musicPos >= 280) then
									local notePos
									local ratingAnim

									notMissed[noteNum] = true

									if settings.downscroll then
										notePos = math.abs(400 - (boyfriendNote[i].y - musicPos))
									else
										notePos = math.abs(-400 - (boyfriendNote[i].y - musicPos))
									end

									voices:setVolume(1)

									if notePos <= 30 then -- "Sick"
										score = score + 350
										ratingAnim = "sick"
									elseif notePos <= 70 then -- "Good"
										score = score + 200
										ratingAnim = "good"
									elseif notePos <= 90 then -- "Bad"
										score = score + 100
										ratingAnim = "bad"
									else -- "Shit"
										if settings.kadeInput then
											success = false
										else
											score = score + 50
										end
										ratingAnim = "shit"
									end
									combo = combo + 1

									rating:animate(ratingAnim, false)
									numbers[1]:animate(tostring(math.floor(combo / 100 % 10), false))
									numbers[2]:animate(tostring(math.floor(combo / 10 % 10), false))
									numbers[3]:animate(tostring(math.floor(combo % 10), false))

									for i = 1, 5 do
										if ratingTimers[i] then Timer.cancel(ratingTimers[i]) end
									end

									ratingVisibility[1] = 1
									rating.y = girlfriend.y - 50
									for i = 1, 3 do
										numbers[i].y = girlfriend.y + 50
									end

									ratingTimers[1] = Timer.tween(2, ratingVisibility, {0})
									ratingTimers[2] = Timer.tween(2, rating, {y = girlfriend.y - 100}, "out-elastic")
									ratingTimers[3] = Timer.tween(2, numbers[1], {y = girlfriend.y + love.math.random(-10, 10)}, "out-elastic")
									ratingTimers[4] = Timer.tween(2, numbers[2], {y = girlfriend.y + love.math.random(-10, 10)}, "out-elastic")
									ratingTimers[5] = Timer.tween(2, numbers[3], {y = girlfriend.y + love.math.random(-10, 10)}, "out-elastic")

									table.remove(boyfriendNote, i)

									if not settings.kadeInput or success then
										boyfriendArrow:animate("confirm", false)

										self:safeAnimate(boyfriend, curAnim, false, 3)

										health = health + 1

										success = true
									end
								else
									break
								end
							end
						end
					end

					if not success then
						audio.playSound(sounds.miss[love.math.random(3)])

						notMissed[noteNum] = false

						if combo >= 5 then self:safeAnimate(girlfriend, "sad", true, 1) end

						self:safeAnimate(boyfriend, "miss " .. curAnim, false, 3)

						score = score - 10
						combo = 0
						health = health - 2
					end
				end

				if notMissed[noteNum] and #boyfriendNote > 0 and input:down(curInput) and ((not settings.downscroll and boyfriendNote[1].y - musicPos <= -400) or (settings.downscroll and boyfriendNote[1].y - musicPos >= 400)) and (boyfriendNote[1]:getAnimName() == "hold" or boyfriendNote[1]:getAnimName() == "end") then
					voices:setVolume(1)

					table.remove(boyfriendNote, 1)

					boyfriendArrow:animate("confirm", false)

					if (not boyfriend:isAnimated()) or boyfriend:getAnimName() == "idle" then self:safeAnimate(boyfriend, curAnim, true, 3) end

					health = health + 1
				end

				if input:released(curInput) then
					boyfriendArrow:animate("off", false)
				end
			end

			if health > 100 then
				health = 100
			elseif health > 20 and boyfriendIcon:getAnimName() == "boyfriend losing" then
				boyfriendIcon:animate("boyfriend", false)
			elseif health <= 0 then -- Game over
				Gamestate.push(gameOver)
			elseif health <= 20 and boyfriendIcon:getAnimName() == "boyfriend" then
				boyfriendIcon:animate("boyfriend losing", false)
			end

			enemyIcon.x = 425 - health * 10
			boyfriendIcon.x = 585 - health * 10

			if musicThres ~= oldMusicThres and math.fmod(absMusicTime, 60000 / bpm) < 100 then
				if enemyIconTimer then Timer.cancel(enemyIconTimer) end
				if boyfriendIconTimer then Timer.cancel(boyfriendIconTimer) end

				enemyIconTimer = Timer.tween((60 / bpm) / 16, enemyIcon, {sizeX = 1.75, sizeY = 1.75}, "out-quad", function() enemyIconTimer = Timer.tween((60 / bpm), enemyIcon, {sizeX = 1.5, sizeY = 1.5}, "out-quad") end)
				boyfriendIconTimer = Timer.tween((60 / bpm) / 16, boyfriendIcon, {sizeX = -1.75, sizeY = 1.75}, "out-quad", function() boyfriendIconTimer = Timer.tween((60 / bpm), boyfriendIcon, {sizeX = -1.5, sizeY = 1.5}, "out-quad") end)
			end

			if not countingDown and input:pressed("gameBack") then
				if inst then inst:stop() end
				voices:stop()

				storyMode = false
			end
		elseif pixelTime then
			if settings.downscroll then
				musicPos = -musicTime * 0.12 * speed
			else
				musicPos = musicTime * 0.12 * speed
			end
	
			for i = 1, 4 do
				local enemyArrow = enemyArrows2[i]
				local boyfriendArrow = boyfriendArrows2[i]
				local enemyNote = enemyNotes[i]
				local boyfriendNote = boyfriendNotes[i]
				local curAnim = animList[i]
				local curInput = inputList[i]
	
				local noteNum = i
	
				enemyArrow:update(dt)
				boyfriendArrow:update(dt)
	
				if not enemyArrow:isAnimated() then
					enemyArrow:animate("off", false)
				end
	
				if #enemyNote > 0 then
					if (not settings.downscroll and enemyNote[1].y - musicPos <= -55) or (settings.downscroll and enemyNote[1].y - musicPos >= 55) then
						voices:setVolume(1)
	
						enemyArrow:animate("confirm", false)
	
						if useAltAnims then
							self:safeAnimate(enemy, curAnim .. " alt", false, 2)
						else
							self:safeAnimate(enemy, curAnim, false, 2)
						end
	
						table.remove(enemyNote, 1)
					end
				end
	
				if #boyfriendNote > 0 then
					if (not settings.downscroll and boyfriendNote[1].y - musicPos < -75) or (settings.downscroll and boyfriendNote[1].y - musicPos > 75) then
						if inst then voices:setVolume(0) end
	
						notMissed[noteNum] = false
	
						table.remove(boyfriendNote, 1)
	
						combo = 0
						health = health - 2
					end
				end
	
				if input:pressed(curInput) then
					local success = false
	
					if settings.kadeInput then
						success = true
					end
	
					boyfriendArrow:animate("press", false)
	
					if #boyfriendNote > 0 then
						for i = 1, #boyfriendNote do
							if boyfriendNote[i] and boyfriendNote[i]:getAnimName() == "on" then
								if (not settings.downscroll and boyfriendNote[i].y - musicPos <= -31) or (settings.downscroll and boyfriendNote[i].y - musicPos >= 31) then
									local notePos
									local ratingAnim
	
									notMissed[noteNum] = true
	
									if settings.downscroll then
										notePos = math.abs(55 - (boyfriendNote[i].y - musicPos))
									else
										notePos = math.abs(-55 - (boyfriendNote[i].y - musicPos))
									end
	
									voices:setVolume(1)
	
									if notePos <= 6 then -- "Sick"
										score = score + 350
										ratingAnim = "sick"
									elseif notePos <= 14 then -- "Good"
										score = score + 200
										ratingAnim = "good"
									elseif notePos <= 18 then -- "Bad"
										score = score + 100
										ratingAnim = "bad"
									else -- "Shit"
										if settings.kadeInput then
											success = false
										else
											score = score + 50
										end
										ratingAnim = "shit"
									end
									combo = combo + 1
	
									rating:animate(ratingAnim, false)
									numbers[1]:animate(tostring(math.floor(combo / 100 % 10), false))
									numbers[2]:animate(tostring(math.floor(combo / 10 % 10), false))
									numbers[3]:animate(tostring(math.floor(combo % 10), false))
	
									for i = 1, 5 do
										if ratingTimers[i] then Timer.cancel(ratingTimers[i]) end
									end
	
									ratingVisibility[1] = 1
									rating.y = girlfriend.y + 5
									for i = 1, 3 do
										numbers[i].y = girlfriend.y + 22
									end
	
									ratingTimers[1] = Timer.tween(2, ratingVisibility, {0})
									ratingTimers[2] = Timer.tween(2, rating, {y = girlfriend.y - 10}, "out-elastic")
									ratingTimers[3] = Timer.tween(2, numbers[1], {y = girlfriend.y + love.math.random(6, 10)}, "out-elastic")
									ratingTimers[4] = Timer.tween(2, numbers[2], {y = girlfriend.y + love.math.random(6, 10)}, "out-elastic")
									ratingTimers[5] = Timer.tween(2, numbers[3], {y = girlfriend.y + love.math.random(6, 10)}, "out-elastic")
	
									table.remove(boyfriendNote, i)
	
									if not settings.kadeInput or success then
										boyfriendArrow:animate("confirm", false)
	
										self:safeAnimate(boyfriend, curAnim, false, 3)
	
										health = health + 1
	
										success = true
									end
								else
									break
								end
							end
						end
					end
	
					if not success then
						audio.playSound(sounds.miss[love.math.random(3)])
	
						notMissed[noteNum] = false
	
						self:safeAnimate(boyfriend, "miss " .. curAnim, false, 3)
	
						score = score - 10
						combo = 0
						health = health - 2
					end
				end
	
				if #boyfriendNote > 0 then
					if input:down(curInput) then
						if ((not settings.downscroll and boyfriendNote[1].y - musicPos <= -55) or (settings.downscroll and boyfriendNote[1].y - musicPos >= 55)) and (boyfriendNote[1]:getAnimName() == "hold" or boyfriendNote[1]:getAnimName() == "end") then
							voices:setVolume(1)
	
							table.remove(boyfriendNote, 1)
	
							boyfriendArrow:animate("confirm", false)
	
							self:safeAnimate(boyfriend, curAnim, true, 3)
	
							health = health + 1
						end
					end
				end
	
				if input:released(curInput) then
					boyfriendArrow:animate("off", false)
				end
			end
	
			if health > 100 then
				health = 100
			elseif health <= 0 then -- Game over
				if inst then inst:stop() end
				voices:stop()
	
				audio.playSound(sounds["death"])
	
				Gamestate.push(gameOverPixel, canvas)
			end
	
			enemyIcon.x = 50 - health * 1.2
			boyfriendIcon.x = 70 - health * 1.2
	
			if musicThres ~= oldMusicThres and math.fmod(absMusicTime, 60000 / bpm) < 100 then
				if enemyIconTimer then Timer.cancel(enemyIconTimer) end
				if boyfriendIconTimer then Timer.cancel(boyfriendIconTimer) end
	
				enemyIconTimer = Timer.tween((60 / bpm) / 16, enemyIcon, {sizeX = 1.25, sizeY = 1.25}, "out-quad", function() enemyIconTimer = Timer.tween((60 / bpm), enemyIcon, {sizeX = 1, sizeY = 1}, "out-quad") end)
				boyfriendIconTimer = Timer.tween((60 / bpm) / 16, boyfriendIcon, {sizeX = -1.25, sizeY = 1.25}, "out-quad", function() boyfriendIconTimer = Timer.tween((60 / bpm), boyfriendIcon, {sizeX = -1, sizeY = 1}, "out-quad") end)
			end
	
			if input:pressed("gameBack") then
				if inst then inst:stop() end
				voices:stop()
	
				storyMode = false
			end
		end
	end,

	drawRating = function(self, multiplier)
		if not pixelTime then
			love.graphics.push()
				if multiplier then
					love.graphics.translate(cam.x * multiplier, cam.y * multiplier)
				else
					love.graphics.translate(cam.x, cam.y)
				end

				graphics.setColor(1, 1, 1, ratingVisibility[1])
				rating:draw()
				for i = 1, 3 do
					numbers[i]:draw()
				end
				graphics.setColor(1, 1, 1)
			love.graphics.pop()
		elseif pixelTime then
			love.graphics.push()
				if multiplier then
					love.graphics.translate(cam.x * multiplier, cam.y * multiplier)
				else
					love.graphics.translate(cam.x, cam.y)
				end

				graphics.setColor(1, 1, 1, ratingVisibility[1])
				rating:draw()
				for i = 1, 3 do
					numbers[i]:draw()
				end
				graphics.setColor(1, 1, 1)
			love.graphics.pop()
		end
	end,

	drawUI = function(self)
		if not pixelTime then
			love.graphics.push()
				love.graphics.translate(lovesize.getWidth() / 2, lovesize.getHeight() / 2)
				love.graphics.scale(0.7, 0.7)

				for i = 1, 4 do
					if enemyArrows[i]:getAnimName() == "off" then
						graphics.setColor(0.6, 0.6, 0.6)
					end
					enemyArrows[i]:draw()
					graphics.setColor(1, 1, 1)
					boyfriendArrows[i]:draw()

					love.graphics.push()
						love.graphics.translate(0, -musicPos)

						for j = #enemyNotes[i], 1, -1 do
							if (not settings.downscroll and enemyNotes[i][j].y - musicPos <= 560) or (settings.downscroll and enemyNotes[i][j].y - musicPos >= -560) then
								local animName = enemyNotes[i][j]:getAnimName()

								if animName == "hold" or animName == "end" then
									graphics.setColor(1, 1, 1, 0.5)
								end
								enemyNotes[i][j]:draw()
								graphics.setColor(1, 1, 1)
							end
						end
						for j = #boyfriendNotes[i], 1, -1 do
							if (not settings.downscroll and boyfriendNotes[i][j].y - musicPos <= 560) or (settings.downscroll and boyfriendNotes[i][j].y - musicPos >= -560) then
								local animName = boyfriendNotes[i][j]:getAnimName()

								if settings.downscroll then
									if animName == "hold" or animName == "end" then
										graphics.setColor(1, 1, 1, math.min(0.5, (500 - (boyfriendNotes[i][j].y - musicPos)) / 150))
									else
										graphics.setColor(1, 1, 1, math.min(1, (500 - (boyfriendNotes[i][j].y - musicPos)) / 75))
									end
								else
									if animName == "hold" or animName == "end" then
										graphics.setColor(1, 1, 1, math.min(0.5, (500 + (boyfriendNotes[i][j].y - musicPos)) / 150))
									else
										graphics.setColor(1, 1, 1, math.min(1, (500 + (boyfriendNotes[i][j].y - musicPos)) / 75))
									end
								end
								boyfriendNotes[i][j]:draw()
							end
						end
						graphics.setColor(1, 1, 1)
					love.graphics.pop()
				end

				if settings.downscroll then
					graphics.setColor(1, 0, 0)
					love.graphics.rectangle("fill", -500, -400, 1000, 25)
					graphics.setColor(0, 1, 0)
					love.graphics.rectangle("fill", 500, -400, -health * 10, 25)
					graphics.setColor(0, 0, 0)
					love.graphics.setLineWidth(10)
					love.graphics.rectangle("line", -500, -400, 1000, 25)
					love.graphics.setLineWidth(1)
					graphics.setColor(1, 1, 1)
				else
					graphics.setColor(1, 0, 0)
					love.graphics.rectangle("fill", -500, 350, 1000, 25)
					graphics.setColor(0, 1, 0)
					love.graphics.rectangle("fill", 500, 350, -health * 10, 25)
					graphics.setColor(0, 0, 0)
					love.graphics.setLineWidth(10)
					love.graphics.rectangle("line", -500, 350, 1000, 25)
					love.graphics.setLineWidth(1)
					graphics.setColor(1, 1, 1)
				end

				boyfriendIcon:draw()
				enemyIcon:draw()

				if settings.downscroll then
					love.graphics.print("Score: " .. score, 300, -350)
				else
					love.graphics.print("Score: " .. score, 300, 400)
				end

				graphics.setColor(1, 1, 1, countdownFade[1])
				countdown:draw()
				graphics.setColor(1, 1, 1)
			love.graphics.pop()
		elseif pixelTime then
			love.graphics.push()
				love.graphics.translate(graphics.getWidth() / 2, graphics.getHeight() / 2)

				for i = 1, 4 do
					if enemyArrows2[i]:getAnimName() == "off" then
						graphics.setColor(0.6, 0.6, 0.6)
					end
					enemyArrows2[i]:draw()
					graphics.setColor(1, 1, 1)
					boyfriendArrows2[i]:draw()

					love.graphics.push()
						love.graphics.translate(0, -musicPos)

						for j = #enemyNotes2[i], 1, -1 do
							if (not settings.downscroll and enemyNotes2[i][j].y - musicPos <= 112) or (settings.downscroll and enemyNotes2[i][j].y - musicPos >= -112) then
								local animName = enemyNotes2[i][j]:getAnimName()

								if animName == "hold" or animName == "end" then
									graphics.setColor(1, 1, 1, 0.5)
								end
								enemyNotes[i][j]:draw()
								graphics.setColor(1, 1, 1)
							end
						end
						for j = #boyfriendNotes2[i], 1, -1 do
							if (not settings.downscroll and boyfriendNotes2[i][j].y - musicPos <= 112) or (settings.downscroll and boyfriendNote2s[i][j].y - musicPos >= -112) then
								local animName = boyfriendNotes2[i][j]:getAnimName()

								if settings.downscroll then
									if animName == "hold" or animName == "end" then
										graphics.setColor(1, 1, 1, math.min(0.5, (75 - (boyfriendNotes2[i][j].y - musicPos)) / 30))
									else
										graphics.setColor(1, 1, 1, math.min(1, (75 - (boyfriendNotes2[i][j].y - musicPos)) / 15))
									end
								else
									if animName == "hold" or animName == "end" then
										graphics.setColor(1, 1, 1, math.min(0.5, (75 + (boyfriendNotes2[i][j].y - musicPos)) / 30))
									else
										graphics.setColor(1, 1, 1, math.min(1, (75 + (boyfriendNotes2[i][j].y - musicPos)) / 15))
									end
								end
								boyfriendNotes2[i][j]:draw()
							end
						end
						graphics.setColor(1, 1, 1)
					love.graphics.pop()
				end

				if settings.downscroll then
					graphics.setColor(1, 0, 0)
					love.graphics.rectangle("fill", -60, -55, 120, 5)
					graphics.setColor(0, 1, 0)
					love.graphics.rectangle("fill", 60, -55, math.floor(-health * 1.2), 5)
					graphics.setColor(0, 0, 0)
					love.graphics.setLineWidth(2)
					love.graphics.rectangle("line", -60, -55, 120, 5)
					love.graphics.setLineWidth(1)
					graphics.setColor(1, 1, 1)
				else
					graphics.setColor(1, 0, 0)
					love.graphics.rectangle("fill", -60, 45, 120, 5)
					graphics.setColor(0, 1, 0)
					love.graphics.rectangle("fill", 60, 45, math.floor(-health * 1.2), 5)
					graphics.setColor(0, 0, 0)
					love.graphics.setLineWidth(2)
					love.graphics.rectangle("line", -60, 45, 120, 5)
					love.graphics.setLineWidth(1)
					graphics.setColor(1, 1, 1)
				end

				boyfriendIcon:draw()
				enemyIcon:draw()

				if settings.downscroll then
					love.graphics.print("Score: " .. score, 0, -50)
				else
					love.graphics.print("Score: " .. score, 0, 50)
				end

				graphics.setColor(1, 1, 1, countdownFade[1])
				countdown:draw()
				graphics.setColor(1, 1, 1)
			love.graphics.pop()
		end
	end,

	leave = function(self)
		if inst then inst:stop() end
		voices:stop()

		Timer.clear()

		fakeBoyfriend = nil
	end
}
