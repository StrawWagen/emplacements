AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
    self.flightvector = self:GetForward() * 35 -- valid default flight vector incase shell is spawned standalone
    self.timeleft = CurTime() + 15
    self.AirburstTime = CurTime() + 15
    self:SetModel( "models/items/ar2_grenade.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS ) -- Make us work with physics,  	
    self:SetMoveType( MOVETYPE_NONE ) --after all, gmod is a physics  	
    self:SetSolid( SOLID_VPHYSICS ) -- CHEESECAKE!	>:3		   
    Tracer = ents.Create( "env_spritetrail" )
    Tracer:SetKeyValue( "lifetime", "0.3" )
    Tracer:SetKeyValue( "startwidth", "32" )
    Tracer:SetKeyValue( "endwidth", "0" )
    Tracer:SetKeyValue( "spritename", "trails/laser.vmt" )
    Tracer:SetKeyValue( "rendermode", "5" )
    Tracer:SetKeyValue( "rendercolor", "255 255 255" )
    Tracer:SetPos( self:GetPos() )
    Tracer:SetParent( self )
    Tracer:Spawn()
    Tracer:Activate()
    Glow = ents.Create( "env_sprite" )
    Glow:SetKeyValue( "model", "orangecore2.vmt" )
    Glow:SetKeyValue( "rendercolor", "37 138 210" )
    Glow:SetKeyValue( "scale", "0.1" )
    Glow:SetPos( self:GetPos() )
    Glow:SetParent( self )
    Glow:Spawn()
    Glow:Activate()
end

function ENT:Think()
    if self.timeleft < CurTime() then
        self:Remove()
    end

    if self.AirburstTime < CurTime() then
        local owner = IsValid( self:GetOwner() ) and self:GetOwner()
        local inflictor = owner or self.Turret
        util.BlastDamage( inflictor, self.Turret, self:GetPos(), 700, 100 )
        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        effectdata:SetScale( 2 )
        effectdata:SetMagnitude( 20 )
        util.Effect( "gdca_airburst_t", effectdata )
        self:Remove()
    end
    
    local trace = {}
    trace.start = self:GetPos()
    trace.endpos = self:GetPos() + self.flightvector
    trace.filter = self
    trace.mask = MASK_SHOT + MASK_WATER -- Trace for stuff that bullets would normally hit
    local tr = util.TraceLine( trace )

    if tr.Hit then
        if tr.HitSky then
            self:Remove()

            return true
        end

        --83 is wata
        if tr.MatType == 83 then
            local effectdata = EffectData()
            effectdata:SetOrigin( tr.HitPos )
            effectdata:SetNormal( tr.HitNormal ) -- In case you hit sideways water?
            effectdata:SetScale( 60 ) -- Big splash for big bullets
            util.Effect( "watersplash", effectdata )
            self:Remove()

            return true
        end
        
        -- damage equals 400 multiplied by two thirds of this turret's firing speed
        local baseDamage = 185
        
        local owner = IsValid( self:GetOwner() ) and self:GetOwner()
        local attacker = owner or self.Turret or self
        local inflictor = self.Turret or self -- makes shell work if spawned standalone        
        
        util.BlastDamage( inflictor, attacker, self:GetPos(), 350, baseDamage )
        
        local concrete = 67 -- has to be concrete else errors are spammed
        local effectdata = EffectData()
        effectdata:SetOrigin( tr.HitPos ) -- Position of Impact
        effectdata:SetNormal( tr.HitNormal ) -- Direction of Impact
        effectdata:SetStart( self.flightvector:GetNormalized() ) -- Direction of Round
        effectdata:SetEntity( self ) -- Who done it?
        effectdata:SetScale( 0.8 ) -- Size of explosion
        effectdata:SetRadius( concrete ) -- Texture of Impact
        effectdata:SetMagnitude( 16 ) -- Length of explosion trails	
        util.Effect( "gdca_airburst_t", effectdata )
        util.ScreenShake( tr.HitPos, 10, 5, 1, 1300 )
        util.Decal( "Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal )
        self:Remove()
    end

    self:SetPos( self:GetPos() + self.flightvector )
    self.flightvector = self.flightvector + ( Vector( math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ), math.Rand( -0.1, 0.1 ) ) + Vector( 0, 0, math.Rand( 0, -0.32 ) ) )
    self:SetAngles( self.flightvector:Angle() )
    self:NextThink( CurTime() )

    return true
end
