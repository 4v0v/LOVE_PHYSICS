--[[
           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 1.0, March 2000

           Copyright (C) 2020 - 4v0v

           Everyone is permitted to copy and distribute verbatim copies
           of this license document, but changing it is not allowed.

           Ok, the purpose of this license is simple
           and you just

           DO WHAT THE FUCK YOU WANT TO.
]]--

local World, Collider, Shape, lg, lp = {}, {}, {}, love.graphics, love.physics
local _uid = function() local fn = function() local r = math.random(16) return ("0123456789ABCDEF"):sub(r, r) end return ("xxxxxxxxxxxxxxxx"):gsub("[x]", fn) end
local _set_funcs = function(a, ...) 
    local args = {...}
    local _f = {__gc=0,__eq=0,__index=0,__tostring=0,isDestroyed=0,testPoint=0,getType=0,raycast=0,destroy=0,setUserData=0,getUserData=0,release=0,type=0,typeOf=0}
    for _, arg in pairs(args) do for k, v in pairs(arg.__index) do if not _f[k] then a[k] = function(a, ...) return v(arg, ...) end end end end
end

-------------------------------
--  <°)))>< <°)))>< <°)))><  --
-------------------------------

function World:new(xg, yg, sleep)
    local function _callback(callback, fix1, fix2, contact, ...)
        if fix1:getUserData() and fix2:getUserData() then
            local shape1, shape2 = fix1:getUserData() , fix2:getUserData()
            local coll1 , coll2  = fix1:getBody():getUserData(), fix2:getBody():getUserData()
            local ctitle         = coll1._id  .. "\t" .. coll2._id
            local stitle         = shape1._id .. "\t" .. shape2._id
            local world          = coll1._world

            world[callback](shape1, shape2, contact, false, ...)
            shape1[callback](shape1, shape2, contact, false, ...)        
            shape2[callback](shape2, shape1, contact, true,  ...) 
            if callback == "_pre" or callback == "_post" then
                coll1[callback](shape1, shape2, contact, false)
                coll2[callback](shape2, shape1, contact, true)
            
            elseif callback == "_enter" then 
                if not world._collisions[ctitle] then 
                    world._collisions[ctitle] = {}
                    coll1._enter(shape1, shape2, contact, false)
                    coll2._enter(shape2, shape1, contact, true)
                end
                table.insert(world._collisions[ctitle], stitle)
            elseif callback == "_exit" then
                for i,v in pairs(world._collisions[ctitle]) do if v == stitle then table.remove(world._collisions[ctitle], i) break end end
                if #world._collisions[ctitle] == 0 then 
                    world._collisions[ctitle] = nil
                    coll1._exit(shape1, shape2, contact, false)
                    coll2._exit(shape2, shape1, contact, true)
                end
            end
        end
    end
    local function _enter(fix1, fix2, contact)      _callback("_enter", fix1, fix2, contact)      end
    local function _exit(fix1, fix2, contact)       _callback("_exit" , fix1, fix2, contact)      end
    local function _pre(fix1, fix2, contact)        _callback("_pre"  , fix1, fix2, contact)      end
    local function _post(fix1, fix2, contact, ...)  _callback("_post" , fix1, fix2, contact, ...) end -- ... => normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2
    -----------------------------
    local obj = {
        _b2d          = lp.newWorld(xg, yg, sleep),
        _colliders    = {},
        _joints       = {},
        _classes      = {},
        _classes_mask = {},
        _collisions   = {},
        _queries      = {},
        _query_color= {0, 0.8,   1,  1},
        _joint_color= {1, 0.5, 0.25, 1},
        _enter        = function() end,
        _exit         = function() end,
        _pre          = function() end,
        _post         = function() end
    }
    -----------------------------
    _set_funcs(obj, obj._b2d)
    setmetatable(obj, {__index = World})
    obj:setCallbacks(_enter, _exit, _pre, _post)
    obj:addClass("Default")

    return obj
end
function World:draw()
    local _r, _g, _b, _a = lg.getColor()
    -- Colliders --
    for k1,v1 in pairs(self:getBodies()) do for k2, v2 in pairs(v1:getFixtures()) do
        local _shape = v2:getUserData()
        lg.setColor(_shape._color.r, _shape._color.g, _shape._color.b, _shape._color.a)
        if     v2:getShape():getType() == "circle"  then 
            local _x, _y = v2:getShape():getPoint()
            lg.push()
            lg.translate(v1:getX(), v1:getY())
            lg.rotate(v1:getAngle())
                lg.circle(_shape._draw_mode, _x, _y, v2:getShape():getRadius())
            lg.pop()
        elseif v2:getShape():getType() == "polygon" then lg.polygon(_shape._draw_mode, v1:getWorldPoints(v2:getShape():getPoints()))
        else   local _p = {v1:getWorldPoints(v2:getShape():getPoints())}; for i=1, #_p, 2 do if i < #_p-2 then lg.line(_p[i], _p[i+1], _p[i+2], _p[i+3]) end end end
    end end
    -- Joints --
    lg.setColor(self._joint_color)
    for _, joint in ipairs(self:getJoints()) do
        local x1, y1, x2, y2 = joint:getAnchors()
        if x1 and y1 then lg.circle('line', x1, y1, 6) end
        if x2 and y2 then lg.circle('line', x2, y2, 6) end
    end
    -- Queries --
    lg.setColor(self._query_color)
    for i = #self._queries, 1, -1 do 
        local _query = self._queries[i] 
        if     _query.type == "circle"   then lg.circle("line", _query.x, _query.y, _query.r)
        elseif _query.type =="rectangle" then lg.rectangle("line", _query.x, _query.y, _query.w, _query.h)
        elseif _query.type == "polygon"  then lg.polygon("line", _query.vertices) 
        elseif _query.type == "line"     then lg.line(_query.x1, _query.y1, _query.x2, _query.y2)  end
        _query.frames = _query.frames - 1
        if _query.frames == 0 then  table.remove(self._queries, i) end
    end
    lg.setColor(_r, _g, _b, _a)
end
function World:setQueryColor(r,g,b,a) self._query_color = {r, g, b, a} return self end
function World:setJointColor(r,g,b,a) self._joint_color = {r, g, b, a} return self end
function World:setEnter(fn)     self._enter = fn return self end
function World:setExit(fn)      self._exit  = fn return self end
function World:setPresolve(fn)  self._pre   = fn return self end
function World:setPostsolve(fn) self._post  = fn return self end
function World:addClass(tag, ignore)
    local function sa(t1, t2) for k in pairs(t1) do if not t2[k] then return false end end for k in pairs(t2) do if not t1[k] then return false end end return true end
    local function a(g) local r = {} for l, _ in pairs(g) do r[l] = {} for k,v in pairs(g) do for _ ,v2 in pairs(v) do if v2 == l then r[l][k] = "" end end end end return r end
    local function b(g) local r = {} for k,v in pairs(g) do table.insert(r, v) end for i = #r, 1,-1 do  local s = false for j = #r, 1, -1 do if i ~= j and sa(r[i], r[j]) then s = true end end if s then table.remove( r, i ) end end return r end
    local function c(t1, t2) local r = {} for i, v in pairs(t2) do for l,v2 in pairs(t1) do if sa(v, v2) then r[l] = i end end end return r end
    -----------------------------
    local ignore = ignore or {}
    self._classes[tag] = ignore
    self._classes_mask = c(a(self._classes), b(a(self._classes)))

    for k,v in pairs(self._colliders) do v:setClass(v._class) end
    return self
end
function World:addJoint(joint_type, col1, col2, ...)
    local _jt,_joint, _j  = joint_type, {}
    if     _jt == "distance"  then _j = lp.newDistanceJoint(col1._body, col2._body, ...)
    elseif _jt == "friction"  then _j = lp.newFrictionJoint(col1._body, col2._body, ...)
    elseif _jt == "gear"      then _j = lp.newGearJoint(col1._joint, col2._joint, ...)    
    elseif _jt == "motor"     then _j = lp.newMotorJoint(col1._body, col2._body, ...)             
    elseif _jt == "mouse"     then _j = lp.newMouseJoint(col1._body, col2, ...) -- col2 = x, ... = y      
    elseif _jt == "prismatic" then _j = lp.newPrismaticJoint(col1._body, col2._body, ...)
    elseif _jt == "pulley"    then _j = lp.newPulleyJoint(col1._body, col2._body, ...)  
    elseif _jt == "revolute"  then _j = lp.newRevoluteJoint(col1._body, col2._body, ...)
    elseif _jt == "rope"      then _j = lp.newRopeJoint(col1._body, col2._body, ...)    
    elseif _jt == "weld"      then _j = lp.newWeldJoint(col1._body, col2._body, ...)    
    elseif _jt == "wheel"     then _j = lp.newWheelJoint(col1._body, col2._body, ...) end
    -----------------------------
    _joint._id = _uid()
    _joint._joint = _j
    -----------------------------
    _set_funcs(_joint, _joint._joint) 
    self._joints[_joint._id] = _joint

    return _joint 
end
function World:addCollider(collider_type, ...)
    local _w, _ct, _a, _collider, _b, _s = self._b2d, collider_type, {...}, {}
    if     _ct == "circle"    then _b, _s = lp.newBody(_w, _a[1], _a[2], _a[4] or "dynamic"), lp.newCircleShape(_a[3])
    elseif _ct == "rectangle" then _b, _s = lp.newBody(_w, _a[1], _a[2], _a[6] or "dynamic"), lp.newRectangleShape(0, 0, _a[3], _a[4], _a[5] or 0)
    elseif _ct == "polygon"   then _b, _s = lp.newBody(_w, _a[1], _a[2], _a[4] or "dynamic"), lp.newPolygonShape(unpack(_a[3]))
    elseif _ct == "line"      then _b, _s = lp.newBody(_w,     0,     0, _a[5] or "static" ), lp.newEdgeShape(_a[1], _a[2], _a[3], _a[4])
    elseif _ct == "chain"     then _b, _s = lp.newBody(_w,     0,     0, _a[3] or "static" ), lp.newChainShape(_a[1], unpack(_a[2]))  end
    -----------------------------
    _collider._world   = self
    _collider._id      = _uid()
    _collider._tag    = _collider._id
    _collider._class   = ""
    _collider._enter   = function() end
    _collider._exit    = function() end
    _collider._pre     = function() end
    _collider._post    = function() end
    _collider._body    = _b
    _collider._shapes  = {
        main = {
            _collider = _collider,
            _id       = "main_" .. _collider._id,
            _tag      = "main",
            _shape    = _s,
            _fixture  = lp.newFixture(_b, _s, 1),
            _enter    = function() end,
            _exit     = function() end,
            _pre      = function() end,
            _post     = function() end,
            _is_visible = true,
            _color      = {r=1, g=1, b=1, a=1},
            _draw_mode  = "line"
        }
    }
    _collider._data       = {}
    _collider._is_visible = true
    _collider._color      = {r=1, g=1, b=1, a=1}
    _collider._draw_mode  = "line"
    -----------------------------
    _collider._shapes["main"]._fixture:setUserData(_collider._shapes["main"])
    _collider._body:setUserData(_collider)
    _set_funcs(_collider, _collider._body, _collider._shapes["main"]._shape, _collider._shapes["main"]._fixture)
    setmetatable(_collider._shapes["main"], {__index = Shape})
    setmetatable(_collider, {__index = Collider})
    _collider:setClass("Default")
    self._colliders[_collider._id] = _collider

    return _collider
end
function World:addCircle(x, y, r, type)            return self:addCollider("circle"   , x, y, r, type)         end
function World:addRectangle(x, y, w, h, rad, type) return self:addCollider("rectangle", x, y, w, h, rad, type) end
function World:addPolygon(x, y, vertices, type)    return self:addCollider("polygon"  , x, y, vertices, type)  end
function World:addLine(x1, y1, x2, y2, type)       return self:addCollider("line"     , x1, y1, x2, y2, type)  end
function World:addChain(loop, vertices, type)      return self:addCollider("chain"    , loop, vertices, type)  end
function World:queryCircle(x, y, r, class)
    local _colliders_list = {}
    for k,v in pairs(self._colliders) do
        local _x,_y = v:getPosition()
        if math.sqrt((_x - x)^2 + (_y - y)^2) <= r then
            if not class then table.insert(_colliders_list, v)
            elseif class then if v:getClass() == class then table.insert(_colliders_list, v) end end
        end
    end
    table.insert(self._queries, {type = "circle", x = x, y = y, r = r, frames = 80 })
    return _colliders_list
end
function World:queryRectangle(x, y, w, h, class)
    local _colliders_list = {}
    for k,v in pairs(self._colliders) do
        local _x,_y = v:getPosition()
        if _x >= x and _x <= x + w and _y >= y and _y <= y + h then
            if not class then table.insert(_colliders_list, v)
            elseif class then if v:getClass() == class then table.insert(_colliders_list, v) end end
        end
    end
    table.insert(self._queries, {type = "rectangle", x = x, y = y, w = w, h = h, frames = 80 })
    return _colliders_list
end
function World:queryPolygon(vertices, class)
    local _colliders_list = {}
    for k,v in pairs(self._colliders) do
        local _x,_y = v:getPosition()
        local _collision, _next = false, 1
        for i = 1, #vertices, 2 do
            _next = i + 2
            if _next > #vertices then _next = 1 end
            local _vcx, _vcy,  _vnx, _vny = vertices[i], vertices[i+1], vertices[_next], vertices[_next+1]
            if (((_vcy >= _y and _vny < _y) or (_vcy < _y and _vny >= _y)) 
            and (_x < (_vnx-_vcx)*(_y-_vcy)/ (_vny-_vcy) + _vcx)) then 
                _collision = not _collision 
            end
        end
        if _collision then
            if not class then table.insert(_colliders_list, v)
            elseif class then if v:getClass() == class then table.insert(_colliders_list, v) end end
        end
    end
    table.insert(self._queries, {type = "polygon", vertices = vertices, frames = 80 })
    return _colliders_list
end
function World:queryLine(x1, y1, x2, y2, class)
    local _colliders_list, _colliders_tag = {}, {}
    self._b2d:rayCast(x1, y1, x2, y2, function(fixture)
        if not class then 
            if not _colliders_tag[fixture:getUserData():getCtag()] then 
                table.insert(_colliders_list, fixture:getUserData():getCollider())
                _colliders_tag[fixture:getUserData():getCtag()] = "flatisjustice"
            end
        else
            if fixture:getUserData():getCollider():getClass() == class then 
                if not _colliders_tag[fixture:getUserData():getCtag()] then 
                    table.insert(_colliders_list, fixture:getUserData():getCollider())
                    _colliders_tag[fixture:getUserData():getCtag()] = "flatisjustice"
                end
            end
        end
        return 1
    end)
    table.insert(self._queries, {type = "line", x1 = x1, y1 = y1, x2 = x2, y2 = y2, frames = 80 })
    return _colliders_list
end
function World:destroy()
    for k,v in pairs(self._colliders) do v:destroy() end
    for k,v in pairs(self._joints) do v:destroy() end
    self.box2d:destroy()
    for k,v in pairs(self) do v = nil end
end

-------------------------------
--  <°)))>< <°)))>< <°)))><  --
-------------------------------

function Collider:setClass(class)
    local class = class or "Default"
    assert( self._world._classes[class] , "Class "  .. class .. " is undefined.")
    self._class = class
    local tmask = {}
    for _, v in pairs(self._world._classes[class]) do table.insert(tmask, self._world._classes_mask[v]) end
    for k, v in pairs(self._shapes) do  v._fixture:setCategory(self._world._classes_mask[class]) v._fixture:setMask(unpack(tmask))end
    return self
end
function Collider:setEnter(fn)     self._enter = fn   return self end
function Collider:setExit(fn)      self._exit  = fn   return self end
function Collider:setPresolve(fn)  self._pre   = fn   return self end
function Collider:setPostsolve(fn) self._post  = fn   return self end
function Collider:setData(data)    self._data  = data return self end
function Collider:setTag(tag)      self._tag   = tag  return self end
function Collider:getClass()    return self._class       end
function Collider:getTag()      return self._tag         end
function Collider:getData(data) return self._data        end
function Collider:getPShape(tag) return self._shapes[tag] end
function Collider:addShape(tag, shape_type, ...)
    assert(not self._shapes[tag], "Collider already have a shape called '" .. tag .."'.") 
    local _st, _a, _shape = shape_type, {...}
    if     _st == "circle"    then _shape = lp.newCircleShape(_a[1], _a[2], _a[3])
    elseif _st == "rectangle" then _shape = lp.newRectangleShape(_a[1], _a[2], _a[3], _a[4], _a[5])
    elseif _st == "polygon"   then _shape = lp.newPolygonShape(unpack(_a[1]))
    elseif _st == "line"      then _shape = lp.newEdgeShape(_a[1], _a[2], _a[3], _a[4])
    elseif _st == "chain"     then _shape = lp.newChainShape(_a[1], unpack(_a[2])) end
    -----------------------------
    self._shapes[tag] = {
        _tag      = tag,
        _id       = tag .. "_" .. self._id,
        _collider = self,
        _shape    = _shape,
        _fixture  = lp.newFixture(self._body, _shape, 1),
        _enter    = function() end,
        _exit     = function() end,
        _pre      = function() end,
        _post     = function() end,
        _is_visible = self._is_visible,
        _color      = {r = self._color.r, g = self._color.g, b =self._color.b, a =self._color.a},
        _draw_mode  = self._draw_mode 
    }
    -----------------------------
    _set_funcs(self._shapes[tag], self._body, self._shapes[tag]._fixture, self._shapes[tag]._shape)
    self._shapes[tag]._fixture:setUserData(self._shapes[tag])
    local tmask = {} for _, v in pairs(self._world._classes[self._class]) do table.insert(tmask, self._world._classes_mask[v]) end
    self._shapes[tag]._fixture:setCategory(self._world._classes_mask[self._class])
    self._shapes[tag]._fixture:setMask(unpack(tmask))
    return setmetatable(self._shapes[tag], {__index = Shape})
end
function Collider:setAlpha(a) 
    self._color.a = a
    for _,v in pairs(self._shapes) do v._color.a = a end 
    return self 
end
function Collider:setColor(r, g, b, a)
    self._color = {r = r, g = g, b = b, a = a or self._color.a}    
    for _,v in pairs(self._shapes) do v._color = {r = r, g = g, b = b, a = a or v._color.a} end 
    return self 
end
function Collider:setDrawMode(mode)
    self._draw_mode = mode
    for _,v in pairs(self._shapes) do v._draw_mode = mode end 
    return self 
end
function Collider:removeShape(tag)
    assert(self._shapes[tag], "Shape '" .. tag .. "' doesn't exist.")
    for k, v in pairs(self._world._collisions) do 
        if k:find(self._id) then 
            for i = #v, 1, -1 do 
                if v[i]:find(self._shapes[tag]._id) then table.remove(self._world._collisions[k], i) end
            end
        end
        if #v == 0 then self._world._collisions[k] = nil end
    end

    self._shapes[tag]._fixture:setUserData(nil)
    self._shapes[tag]._fixture:destroy()
    self._shapes[tag]._fixture  = nil
    self._shapes[tag]._collider = nil
    self._shapes[tag]._shape    = nil
    self._shapes[tag]           = nil
    return self
end
function Collider:destroy()
    for k, v in pairs(self._world._collisions) do if k:find(self._id) then self._world._collisions[k] = nil end end
    self._world._colliders[self._id] = nil 
    self._world = nil

    for k,v in pairs(self._shapes) do 
        v._fixture:setUserData(nil)
        v._fixture:destroy()
        v._fixture  = nil
        v._shape    = nil
        v._collider = nil
    end
    self._data = nil
    self._body:setUserData(nil)
    self._body:destroy()
    self._body = nil
end

-------------------------------
--  <°)))>< <°)))>< <°)))><  --
-------------------------------

function Shape:setEnter(fn)     self._enter = fn return self end
function Shape:setExit(fn)      self._exit  = fn return self end
function Shape:setPresolve(fn)  self._pre   = fn return self end
function Shape:setPostsolve(fn) self._post  = fn return self end
function Shape:setAlpha(a)  self._color.a = a    return self end
function Shape:setColor(r, g, b, a) self._color = {r = r, g = g, b = b, a = a or self._color.a} return self end
function Shape:setDrawMode(mode) self._draw_mode = mode return self end
function Shape:getCollider() return self._collider        end
function Shape:getClass()    return self._collider._class end
function Shape:getCTag()     return self._collider._tag   end
function Shape:getTag()      return self._tag             end
function Shape:destroy() self._collider:removeShape(self._tag) end

-------------------------------
--  <°)))>< <°)))>< <°)))><  --
-------------------------------

return setmetatable({}, {__call = World.new})
