#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ INITIALIZE
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game_Temp
#===============================================================================
class Game_Temp
  attr_accessor :change_leader_wait_time
  attr_accessor :reset_battler_time
  attr_accessor :tool_event
  attr_accessor :animation_garbage
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------   
  alias xas_initialize initialize 
  def initialize
      @change_leader_wait_time = 0
      @reset_battler_time = 0
      @tool_event = nil
      @animation_garbage = []
      xas_initialize
  end
  
end

#===============================================================================
# ■ Game_System
#===============================================================================
class Game_System
  attr_accessor :tools_on_map
  attr_accessor :old_interpreter_running
  attr_accessor :hud_visible
  attr_accessor :enable_hud
  attr_accessor :command_enable
  attr_accessor :pre_leader_id
  attr_accessor :xas_battle
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------   
  alias x_initialize initialize
  def initialize
      @tools_on_map = []
      @old_interpreter_running = false
      @hud_visible = XAS_BA::HUD_VISIBLE_AT_STARTUP
      @enable_hud = false
      @command_enable  = true
      @pre_leader_id = 0
      @xas_battle = XAS_SYSTEM::BATTLE_SYSTEM
      x_initialize
  end  
end  

#===============================================================================
# ■ Game_Battler
#===============================================================================
class Game_Battler < Game_BattlerBase
  attr_accessor :damage_pop
  attr_accessor :damage
  attr_accessor :damage_type
  attr_accessor :critical
  attr_accessor :invunerable_duration
  attr_accessor :shield
  attr_accessor :invunerable_actions
  attr_accessor :guard_directions
  attr_accessor :guard
  attr_accessor :invunerable
  attr_accessor :x_combo
  attr_accessor :cast_action
  attr_accessor :defeated
  attr_accessor :death_zoom_effect
  attr_accessor :counter_action
  attr_accessor :knockback_duration 
  attr_accessor :hp_damage
  attr_accessor :mp_damage
  attr_accessor :collapse_duration_t
  attr_accessor :gain_duration
  
 #--------------------------------------------------------------------------
 # ● Initialize
 #--------------------------------------------------------------------------  
  alias x_initialize initialize 
  def initialize
      @damage = 0
      @damage_pop = false
      @damage_type = 0
      @critical = false
      @invunerable_duration = 0
      @shield = false
      @invunerable_actions = []
      @guard_directions = []
      @guard = true
      @invunerable = false
      @x_combo = [0,-1,0]
      @defeated = false
      @death_zoom_effect = 0
      @cast_action = [0,0,0,0,0]
      @counter_action = [0,0,true]
      @knockback_duration = XAS_BA::DEFAULT_KNOCK_BACK_DURATION
      @collapse_duration_t = XAS_BA::DEFAULT_COLLAPSE_BACK_DURATION
      @gain_duration = 0
      x_initialize
  end
  
  #--------------------------------------------------------------------------
  # ● 대미지의 처리
  #    호출전에 @result.hp_damage @result.mp_damage @result.hp_drain
  #    @result.mp_drain 가 설정되어 있는 것.
  #    ※ 기본공격 또는 스킬 타격 또는 적 스킬 피격
  #--------------------------------------------------------------------------
  def before_execute_damage(user, item = nil)
    if self.is_a?(Game_Actor) && @result.hp_damage > 0
      if @hp - @result.hp_damage < ( mhp * XAS_BA_ENEMY::LOWHP / 100 )
        $game_map.screen.start_flash(Color.new(255, 0, 0), 8)
      else
        $game_map.screen.start_flash(Color.new(255, 0, 0, 50), 8)
      end
    end
    if user.is_a?(Game_Actor) and !item.nil? and user != self
      if XAS_BA_ENEMY::DAMAGE_SET.include?(self.enemy_id)
        if XAS_BA_ENEMY::DAMAGE_SET[self.enemy_id].include?(item.id)
          @result.hp_damage = XAS_BA_ENEMY::DAMAGE_SET[self.enemy_id][item.id].to_i
        end
      end
    end
    if self.state_life && self.hp <= @result.hp_damage
      @result.hp_damage = self.hp - 1
    end
    if user.state_drain
      user.hp += @result.hp_damage
      user.damage = -@result.hp_damage
      user.damage_pop = true
    end
    execute_damage(user)
  end
  
 #--------------------------------------------------------------------------
 # ● Add Invunerable Actions
 #--------------------------------------------------------------------------     
 def add_inv(action_id = 0)
     return if action_id == nil or action_id <= 0
     return if @invunerable_actions.include?(action_id)
     @invunerable_actions.push(action_id)     
 end
 
 #--------------------------------------------------------------------------
 # ● Remove Invunerable Actions
 #--------------------------------------------------------------------------     
 def remove_inv(action_id = 0)
     return if action_id == nil or action_id <= 0
     return unless @invunerable_actions.include?(action_id)
     @invunerable_actions.delete(action_id)     
 end 
   
 #--------------------------------------------------------------------------
 # ● Add Guard Directions
 #--------------------------------------------------------------------------     
 def add_guard_dir(direction = 0)
     return if direction == nil or direction <= 0
     return if @guard_directions.include?(direction)
     @guard_directions.push(direction)     
 end
 
 #--------------------------------------------------------------------------
 # ● Remove Guard Directions
 #--------------------------------------------------------------------------     
 def remove_guard_dir(direction = 0)
     return if direction == nil or direction <= 0
     return unless @guard_directions.include?(direction)
     @guard_directions.delete(direction)     
 end  
  
  #--------------------------------------------------------------------------
  # ● DrainHP Effect 
  #--------------------------------------------------------------------------
  def drainhp_effect(user) 
      return if user.dead?
      return if self.e_item 
      user.damage = -self.damage.to_i
      user.damage_pop = true         
      user.hp += self.damage.to_i        
  end

  #--------------------------------------------------------------------------
  # ● DrainMP Effect 
  #--------------------------------------------------------------------------
  def drainsp_effect(user,old_damage)  
      return if user.dead?
      return if self.e_item 
      damage_mp = -old_damage 
      user.damage = $data_system.words.mp + " " + damage_mp.to_s
      user.damage_pop = true         
      user.mp += old_damage
  end
  
  #------------------------------------------------------------------------ 
  # ● Execute Mp Damage
  #------------------------------------------------------------------------   
  def execute_mp_damage(user, skill = nil)
      old_sp = self.sp
      if self.damage > self.mp
         old_damage = self.mp                 
         real_damage = $data_system.words.mp + " " + self.mp.to_s   
         self.mp -= self.mp     
         self.damage = real_damage        
      else
         old_damage = self.damage         
         real_damage = $data_system.words.mp + " " + self.damage.to_s 
         self.mp -= self.damage   
         self.damage = real_damage
      end
      if skill != nil 
        if $data_skills[skill.id].element_set.include?($data_system.elements.index(XAS_BA_BATTLEEVENT_NONPREEMPT::DRAIN)) or
           user.state_drain   
           drainsp_effect(user,old_damage) 
         end   
      else             
         drainsp_effect(user,old_damage) if user.e_drain 
      end  
  end      
  
  #------------------------------------------------------------------------ 
  # ● Execute Hp Damage
  #------------------------------------------------------------------------   
  def execute_hp_damage(user, skill = nil)
      self.hp -= self.damage.to_i 
      if skill != nil
         if $data_skills[skill.id].element_set.include?($data_system.elements.index(XAS_ELEMENT::DRAIN)) or
         user.state_drain 
         drainhp_effect(user)  
         end
      else   
         drainhp_effect(user) if user.e_drain         
      end  
  end         
 
end  

#===============================================================================
# ■ Game Actor
#===============================================================================
class Game_Actor < Game_Battler
  
  attr_accessor :x_action1_id
  attr_accessor :x_action2_id
  attr_accessor :skill_id
  attr_accessor :x_item_id
  attr_accessor :item_or_skill_1
  attr_accessor :item_or_skill_2
  attr_accessor :item_or_skill_3
  attr_accessor :item_or_skill_4
  attr_accessor :item_or_skill_5
  attr_accessor :item_or_skill_6
  attr_accessor :item_or_skill_7
  attr_accessor :item_or_skill_8
  attr_accessor :item_or_skill_9
  attr_accessor :item_or_skill_0
  attr_accessor :item_extra_1
  attr_accessor :item_extra_2
  attr_accessor :item_extra_3
  attr_accessor :item_extra_4
  attr_accessor :item_extra_5
  attr_accessor :item_extra_6
  attr_accessor :item_extra_7
  attr_accessor :item_extra_8
  attr_accessor :item_extra_9
  attr_accessor :item_extra_0
  attr_accessor :x_charge_action
  attr_accessor :old_equipment_id
  attr_accessor :item_id
  attr_accessor :old_level
  attr_reader :actor_id

 #--------------------------------------------------------------------------
 # ● Setup
 #--------------------------------------------------------------------------    
 alias x_setup setup
 def setup(actor_id)
      @x_action1_id = 0
      @x_action2_id = 0
      @skill_id = 0
      @x_item_id = 0
      @item_or_skill_1 = 0
      @item_or_skill_2 = 0
      @item_or_skill_3 = 0
      @item_or_skill_4 = 0
      @item_or_skill_5 = 0
      @item_or_skill_5 = 0
      @item_or_skill_6 = 0
      @item_or_skill_7 = 0
      @item_or_skill_8 = 0
      @item_or_skill_9 = 0
      @item_or_skill_0 = 0
      @item_extra_1 = 0
      @item_extra_2 = 0
      @item_extra_3 = 0
      @item_extra_4 = 0
      @item_extra_5 = 0
      @item_extra_5 = 0
      @item_extra_6 = 0
      @item_extra_7 = 0
      @item_extra_8 = 0
      @item_extra_9 = 0
      @item_extra_0 = 0
      @item_id = 0
      @x_charge_action = [0,0,0,0]
      @old_level = @level
      @old_equipment_id = [0,0,0,0,0]
      x_setup(actor_id)
 end 
 
 #--------------------------------------------------------------------------
 # ● Display Level Up
 #--------------------------------------------------------------------------     
  alias x_display_level_up display_level_up
  def display_level_up(new_skills)
      return unless $game_party.in_battle 
      x_display_level_up(new_skills)
  end 
  
end

#===============================================================================
# ■ Character 
#===============================================================================
class Game_Character < Game_CharacterBase
  
  attr_accessor :tool_id
  attr_accessor :tool_effect  
  attr_accessor :target
  attr_accessor :target2
  attr_accessor :old_x
  attr_accessor :old_y
  attr_accessor :pre_x
  attr_accessor :pre_y
  attr_accessor :temp_id
  attr_accessor :angle
  attr_accessor :force_action_times
  attr_accessor :force_action
  attr_accessor :move_frequency
  attr_accessor :move_speed
  attr_accessor :direction_fix
  attr_accessor :walk_anime
  attr_accessor :step_anime
  attr_accessor :x
  attr_accessor :y
  attr_accessor :pattern
  attr_accessor :pattern_count  
  attr_accessor :jump_count
  attr_accessor :jump_peak
  attr_accessor :dash_active
  attr_accessor :direction
  attr_accessor :through 
  attr_accessor :bush_depth  
  attr_accessor :blend_type 
  attr_accessor :priority_type  
  attr_accessor :jump_count 
  attr_accessor :zoom_x
  attr_accessor :zoom_y
  attr_accessor :stop
  attr_accessor :force_update
  attr_accessor :treasure_time 
  attr_accessor :treasure_float
  attr_accessor :can_update
  attr_accessor :pre_move_speed
  attr_accessor :knock_back_duration
  attr_accessor :orig_pos_x
  attr_accessor :orig_pos_y
  attr_accessor :shoot_time
  attr_accessor :collapse_done #new
  attr_accessor :hit_reaction #new
  attr_accessor :self_target #new
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------    
  alias x_initialize initialize
  def initialize
      x_initialize
      @tool_id = 0
      @tool_effect = ""
      @target = false
      @target2 = nil
      @old_x = @x
      @old_y = @y
      @pre_x = @x
      @pre_y = @y   
      @orig_pos_x = @x
      @orig_pos_y = @y
      @angle = 0
      @force_action_times = 0
      @force_action = ""
      @dash_active = false
      @zoom_x = 1.00
      @zoom_y = 1.00
      @stop = false
      @force_update = false
      @treasure_time = 0
      @treasure_float = [0,0,0,0]
      @can_update = true
      @temp_id = 0
      @pre_move_speed = @move_speed
      @shoot_time = [0,0]
      @hit_reaction = true #new
      @self_target = 0 #new
  end
  
  #--------------------------------------------------------------------------
  # ● Invunerable
  #--------------------------------------------------------------------------      
  def invunerable(enable = false)
      return if @battler == nil or @battler.dead?
      @battler.invunerable = enable
  end  
  
  #--------------------------------------------------------------------------
  # ● Hud Visible
  #--------------------------------------------------------------------------      
  def hud_switch(enable = false)
      return if @battler == nil or @battler.dead?
      @battler.hud_switch = enable
  end  
  
  #--------------------------------------------------------------------------
  # ● Fast Breath
  #--------------------------------------------------------------------------        
  def fast_breath(enable = true)
     return if @battler == nil or @battler.dead?
     @battler.fast_breath_effect = enable
  end
end

#===============================================================================
# ■ Game_Event 
#===============================================================================
class Game_Event < Game_Character
  attr_accessor :target
  attr_reader   :name
  attr_accessor :collision_attack 
  attr_accessor :delect_swi

 #--------------------------------------------------------------------------
 # ● Object
 #--------------------------------------------------------------------------      
 alias x_event_initialize initialize
 def initialize(map_id, event)
     x_event_initialize(map_id, event)
     @collision_attack = false
     @delect_swi = []
     if @event.name =~ /<O(\d+)>/i
        @opacity = $1.to_i  
     end   
     if @event.name =~ /<B(\d+)>/i   
        @blend_type = $1.to_i 
     end  
 end  
   
 #--------------------------------------------------------------------------
 # ● Erase
 #--------------------------------------------------------------------------        
 alias x_event_erase erase 
 def erase
     if self.tool_id > 0
        $game_system.tools_on_map.delete(self.tool_id)
     end   
     x_event_erase
 end     
  
 #--------------------------------------------------------------------------
 # ● Event Name
 #--------------------------------------------------------------------------
  def name
      return @event.name  
  end   
  
end

#===============================================================================
# ■ Game Followers 
#===============================================================================
class Game_Followers
  
 #--------------------------------------------------------------------------
 # ● Initialize
 #--------------------------------------------------------------------------  
  alias x_party_initialize initialize
  def initialize(leader)
      x_party_initialize(leader)
      if $xas_party_system == nil
         @visible = false
      end  
  end  
end  

#===============================================================================
# ■ Game Map
#===============================================================================
class Game_Map  

 #--------------------------------------------------------------------------
 # ● Setup
 #--------------------------------------------------------------------------  
  alias x_initial_setup setup
  def setup(map_id)
      x_initial_setup(map_id)
      xas_initial_setup(map_id)
  end
  
 #--------------------------------------------------------------------------
 # ● XAS Initial Setup
 #--------------------------------------------------------------------------  
  def xas_initial_setup(map_id)
      for actor in $game_party.members
          setup_initial_members(actor)
      end  
  end  
    
 #--------------------------------------------------------------------------
 # ● Setup Initial Membes
 #--------------------------------------------------------------------------    
  def setup_initial_members(actor)
      
  end  
end  


#==============================================================================
# ■ Scene_Map
#==============================================================================
class Scene_Map < Scene_Base
  
  #--------------------------------------------------------------------------
  # ● Call Menu
  #--------------------------------------------------------------------------    
  alias x_call_menu call_menu
  def call_menu
      return if $game_player.action != nil 
      $game_player.reset_charge_temp
      x_call_menu
  end
    
end    
#===============================================================================
# ■ Scene_Refresh
#===============================================================================
class Scene_Refresh
  
 #--------------------------------------------------------------------------
 # ● Main
 #--------------------------------------------------------------------------
  def main
      SceneManager.call(Scene_Map)
  end
end

#==============================================================================
# ■ Game_Player 
#==============================================================================
class Game_Player < Game_Character

  attr_accessor :delect_swi
 #--------------------------------------------------------------------------
 # ● Leader Changed
 #--------------------------------------------------------------------------  
  def leader_changed?(actor)
      if $game_party.members[0] == nil
         return true if actor != nil
      elsif $game_party.members[0] != nil 
         return true if actor == nil    
         return true if actor.actor_id != $game_party.members[0].actor_id        
      end   
      return false
  end
  
end  
$xas = true


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ MOVEMENT - DIAGONAL MOVEMENT
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game Character
#===============================================================================
class Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # ● 똑바로 이동
  #     d       : 방향(2,4,6,8)
  #     turn_ok : 그 자리로의 향해 변경을 허가
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true)
    d = 5 - d + 5 if self.battler.is_a?(Game_Enemy) && self.battler.state_confuse
    d = ( rand( 4 ) + 1 ) * 2 if self.battler.is_a?(Game_Enemy) && self.battler.state_c_confuse
    @move_succeed = passable?(@x, @y, d)
    if @move_succeed
      set_direction(d)
      if self.battler.is_a?(Game_Enemy)
        if self.battler.state_stop
        else
          @x = $game_map.round_x_with_direction(@x, d)
          @y = $game_map.round_y_with_direction(@y, d)
          @real_x = $game_map.x_with_direction(@x, reverse_dir(d))
          @real_y = $game_map.y_with_direction(@y, reverse_dir(d))
        end
      else
        @x = $game_map.round_x_with_direction(@x, d)
        @y = $game_map.round_y_with_direction(@y, d)
        @real_x = $game_map.x_with_direction(@x, reverse_dir(d))
        @real_y = $game_map.y_with_direction(@y, reverse_dir(d))
      end
      increase_steps
    elsif turn_ok
      set_direction(d)
      check_event_trigger_touch_front
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 비스듬하게 이동
  #     horz : 횡방향(4 or 6)
  #     vert : 세로 방향(2 or 8)
  #--------------------------------------------------------------------------
  def move_diagonal(horz, vert)
    horz = 5 - horz + 5 if self.battler.is_a?(Game_Enemy) && self.battler.state_confuse
    vert = 5 - vert + 5 if self.battler.is_a?(Game_Enemy) && self.battler.state_confuse
    horz = ( rand( 2 ) + 1 ) * 2 + 2 if self.battler.is_a?(Game_Enemy) && self.battler.state_c_confuse
    vert = ( rand( 2 ) + 1 ) * 6 - 4 if self.battler.is_a?(Game_Enemy) && self.battler.state_c_confuse
    @move_succeed = diagonal_passable?(x, y, horz, vert)
    if @move_succeed
      if self.battler.is_a?(Game_Enemy)
        if self.battler.state_stop
        else
          @x = $game_map.round_x_with_direction(@x, horz)
          @y = $game_map.round_y_with_direction(@y, vert)
          @real_x = $game_map.x_with_direction(@x, reverse_dir(horz))
          @real_y = $game_map.y_with_direction(@y, reverse_dir(vert))
        end
      else
        @x = $game_map.round_x_with_direction(@x, horz)
        @y = $game_map.round_y_with_direction(@y, vert)
        @real_x = $game_map.x_with_direction(@x, reverse_dir(horz))
        @real_y = $game_map.y_with_direction(@y, reverse_dir(vert))
      end
      increase_steps
    end
    set_direction(horz) if @direction == reverse_dir(horz)
    set_direction(vert) if @direction == reverse_dir(vert)
  end
  
  #--------------------------------------------------------------------------
  # ● Set Direction
  #--------------------------------------------------------------------------          
   alias diagonal_set_direction set_direction
   def set_direction(d)
       diagonal_set_direction(d)
       @diagonal_direction = 0
       reset_diagonal
   end
  #--------------------------------------------------------------------------
  # ● 반대로 이동
  #     d       : 방향(2,4,6,8)
  #     turn_ok : 그 자리로의 향해 변경을 허가
  #--------------------------------------------------------------------------
  def move_mirror(d, turn_ok = true)
    mirrord = ( 5 - d ) * 2 + d
    @move_succeed = passable?(@x, @y, mirrord)
    if @move_succeed
      set_direction(mirrord)
      @x = $game_map.round_x_with_direction(@x, mirrord)
      @y = $game_map.round_y_with_direction(@y, mirrord)
      @real_x = $game_map.x_with_direction(@x, reverse_dir(mirrord))
      @real_y = $game_map.y_with_direction(@y, reverse_dir(mirrord))
      increase_steps
    elsif turn_ok
      set_direction(mirrord)
      check_event_trigger_touch_front
    end
  end
   
end   

#===============================================================================
# ■  Game Character
#===============================================================================
class Game_Character < Game_CharacterBase
  
  attr_accessor :diagonal
  attr_accessor :diagonal_direction
  attr_accessor :sprite_angle_enable
  attr_accessor :diagonal_time
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------        
  alias diagonal_initialize initialize
  def initialize
      diagonal_initialize
      if XAS_SYSTEM::EVENT_DIAGONAL_MOVEMENT
         @diagonal = true
      else   
         @diagonal = false
      end  
      @diagonal_direction = 0
      @sprite_angle_enable = false
      @diagonal_time = 0
  end  
    
  #--------------------------------------------------------------------------
  # ● Reset Diagonal
  #--------------------------------------------------------------------------            
  def reset_diagonal
      return if @direction_fix
      return if @diagonal == false
      @diagonal_direction = 0    
      @diagonal_time = 0
      @angle = 0 if @sprite_angle_enable
  end  
  
  #--------------------------------------------------------------------------
  # ● Enable Diagonal
  #--------------------------------------------------------------------------            
  def enable_diagonal(dir = 0)
     return if @direction_fix
     return if @diagonal == false
     return if dir == 0
     @diagonal_direction = dir
     @diagonal_time = XAS_BA::DIAGONAL_DURATION
     @angle = 315 if @sprite_angle_enable
  end  
  
  #--------------------------------------------------------------------------
  # ● Turn Upper Right
  #--------------------------------------------------------------------------  
  def turn_upper_right
      enable_diagonal(9)
      @direction = 8 unless @direction_fix
  end  
  
  #--------------------------------------------------------------------------
  # ● Turn Upper Left
  #--------------------------------------------------------------------------  
  def turn_upper_left
      enable_diagonal(7)
      @direction = 4 unless @direction_fix
  end   
  
  #--------------------------------------------------------------------------
  # ● Turn Lower Right
  #--------------------------------------------------------------------------  
  def turn_lower_right
      enable_diagonal(3)
      @direction = 6 unless @direction_fix
  end      
  
  #--------------------------------------------------------------------------
  # ● Turn Lower Left
  #--------------------------------------------------------------------------  
  def turn_lower_left
      enable_diagonal(1)
      @direction = 2 unless @direction_fix
  end   
    
  #--------------------------------------------------------------------------
  # ● Move forward
  #--------------------------------------------------------------------------                
  alias diagonal_move_forward move_forward
  def move_forward
      return if move_forward_diagonal?
      diagonal_move_forward
  end
  
  #--------------------------------------------------------------------------
  # ● Move forward Diagonal?
  #--------------------------------------------------------------------------                  
  def move_forward_diagonal?
      return false if @diagonal == false
      if @diagonal_direction != 0
         case @diagonal_direction
              when 1 #Lower Left
                 move_diagonal(4, 2)
                 @direction = 2
              when 3 #Lower Right
                 move_diagonal(6, 2)
                 @direction = 6
              when 7 #Upper Left
                 move_diagonal(4, 8)
                 @direction = 4
              when 9 #Upper Right
                 move_diagonal(6, 8)
                 @direction = 8
          end
          enable_diagonal(@diagonal_direction)      
         return true
      end  
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Move Backward
  #--------------------------------------------------------------------------                
  alias diagonal_move_backward move_backward
  def move_backward
      return if move_backward_diagonal?
      diagonal_move_backward
  end
  
  #--------------------------------------------------------------------------
  # ● Move Backward Diagonal?
  #--------------------------------------------------------------------------                  
  def move_backward_diagonal?
      return false if @diagonal == false
      if @diagonal_direction != 0
         last_direction_fix = @direction_fix
         @direction_fix = true       
         case @diagonal_direction
              when 1
                 move_diagonal(6, 8)
                 @direction = 6
              when 3
                 move_diagonal(4, 8)
                 @direction = 4
              when 7
                 move_diagonal(6, 2)
                 @direction = 6
              when 9         
                 move_diagonal(4, 2)
                 @direction = 2
         end
         enable_diagonal(@diagonal_direction)      
         @direction_fix = last_direction_fix
         return true
      end  
      return false
  end  
  
  #--------------------------------------------------------------------------
  # ● Turn Toward Player
  #--------------------------------------------------------------------------
  alias turn_toward_player_diagonal turn_toward_player
  def turn_toward_player
      if @diagonal
         diagonal_turn_toward_player
         return 
      end
      turn_toward_player_diagonal
  end  
  
  #--------------------------------------------------------------------------
  # ● Diagonal Turn Toward Player
  #-------------------------------------------------------------------------- 
  def diagonal_turn_toward_player
      sx = distance_x_from($game_player.x)
      sy = distance_y_from($game_player.y)
      sd = sx.abs - sy.abs
      sdx = sd.abs - sx.abs
      sdy = sd.abs - sy.abs
      return if sx == 0 and sy == 0
      #Turn Upper Right
      if sx < 0 and sy > 0
         if sx.abs > sy.abs and sdx.abs < sd.abs
            set_direction(6)
         elsif sx.abs < sy.abs and sdy.abs < sd.abs
            set_direction(8) 
         else
            turn_upper_right
         end
         enable_diagonal(9)
      #Turn Upper Left
      elsif sx > 0 and sy > 0
         if sx.abs > sy.abs and sdx.abs < sd.abs
            set_direction(4)
         elsif sx.abs < sy.abs and sdy.abs < sd.abs
            set_direction(8)            
         else
            set_direction(4)
            turn_upper_left
         end
         enable_diagonal(7)  
      #Turn Lower Left  
      elsif sx > 0 and sy < 0
         if sx.abs > sy.abs and sdx.abs < sd.abs
            set_direction(4)
         elsif sx.abs < sy.abs and sdy.abs < sd.abs
            set_direction(2)         
         else                    
            turn_lower_left
         end
         enable_diagonal(1)   
       #Turn Lower Right    
       elsif sx < 0 and sy < 0         
         if sx.abs > sy.abs and sdx.abs < sd.abs
            set_direction(6)
         elsif sx.abs < sy.abs and sdy.abs < sd.abs
            set_direction(2)           
         else        
            turn_lower_right
         end
         enable_diagonal(3) 
      elsif sx < 0 
         set_direction(6)
      elsif sx > 0 
         set_direction(4)
      elsif sy > 0 
         set_direction(8)
      elsif sy < 0 
         set_direction(2)   
      end     
  
  end  
 
  #--------------------------------------------------------------------------
  # ● Move toward Player
  #--------------------------------------------------------------------------
  def move_toward_player
    if self.self_target > 0
      if self.self_target != 0
      if @diagonal
         diagonal_move_toward_enemy
         return  
      end
      move_toward_character($game_map.events[@self_target])
      end
    else
       if @diagonal
         diagonal_move_toward_player
         return  
       end
      move_toward_character($game_player)
    end
  end   
   
  #--------------------------------------------------------------------------
  # ● Diagonal Move Toward Player
  #--------------------------------------------------------------------------  
  def diagonal_move_toward_player
      sx = distance_x_from($game_player.x)
      sy = distance_y_from($game_player.y)
      if sx == 0 and sy == 0
         return
      end
      abs_sx = sx.abs
      abs_sy = sy.abs
      if abs_sx == abs_sy
        rand(2) == 0 ? abs_sx += 1 : abs_sy += 1
      end
      if abs_sx
         if sx < 0 and sy > 0
            move_diagonal(6, 8)
            move_random unless moving?
            enable_diagonal(9) 
         elsif sx > 0 and sy > 0
            move_diagonal(4, 8)
            move_random unless moving?
            enable_diagonal(7) 
         elsif sx > 0 and sy < 0
            move_diagonal(4, 2)
            move_random unless moving?
            enable_diagonal(1) 
         elsif sx < 0 and sy < 0
            move_diagonal(6, 2)
            move_random unless moving?
            enable_diagonal(3) 
         elsif sx < 0 
            move_straight(6)
         elsif sx > 0 
            move_straight(4)
         elsif sy > 0 
            move_straight(8)
         elsif sy < 0 
            move_straight(2)
         end
         if abs_sx != 1 and abs_sy != 1
            move_random unless moving?
         end  
      end
 end
  
  #--------------------------------------------------------------------------
  # ● Diagonal Move Toward Enemy
  #--------------------------------------------------------------------------  
  def diagonal_move_toward_enemy
      sx = distance_x_from($game_map.events[self.self_target].x)
      sy = distance_y_from($game_map.events[self.self_target].y)
    return if self.battler.is_a?(Game_Actor)
      if sx == 0 and sy == 0
         return
      end
      abs_sx = sx.abs
      abs_sy = sy.abs
      if abs_sx == abs_sy
        rand(2) == 0 ? abs_sx += 1 : abs_sy += 1
      end
      if abs_sx
         if sx < 0 and sy > 0
            move_diagonal(6, 8)
            move_random unless moving?
            enable_diagonal(9) 
         elsif sx > 0 and sy > 0
            move_diagonal(4, 8)
            move_random unless moving?
            enable_diagonal(7) 
         elsif sx > 0 and sy < 0
            move_diagonal(4, 2)
            move_random unless moving?
            enable_diagonal(1) 
         elsif sx < 0 and sy < 0
            move_diagonal(6, 2)
            move_random unless moving?
            enable_diagonal(3) 
         elsif sx < 0 
            move_straight(6)
         elsif sx > 0 
            move_straight(4)
         elsif sy > 0 
            move_straight(8)
         elsif sy < 0 
            move_straight(2)
         end
         if abs_sx != 1 and abs_sy != 1
            move_random unless moving?
         end  
      end
 end
  
 #--------------------------------------------------------------------------
 # ● turn_right_45
 #--------------------------------------------------------------------------      
 def turn_right_45
     if @diagonal and @diagonal_direction != 0     
        case @diagonal_direction
          when 1;  set_direction(4) 
          when 3;  set_direction(2)
          when 7;  set_direction(8)
          when 9;  set_direction(6)  
        end
     else  
        case @direction
          when 2;  turn_lower_left
          when 4;  turn_upper_left
          when 6;  turn_lower_right
          when 8;  turn_upper_right
        end
     end  
 end

 #--------------------------------------------------------------------------
 # ● turn_left_45
 #--------------------------------------------------------------------------  
 def turn_left_45
     if @diagonal and @diagonal_direction != 0     
        case @diagonal_direction
          when 1;  set_direction(2) 
          when 3;  set_direction(6)
          when 7;  set_direction(4)
          when 9;  set_direction(8)
        end
     else  
        case @direction
          when 2;  turn_lower_right
          when 4;  turn_lower_left
          when 6;  turn_upper_right
          when 8;  turn_upper_left
        end
     end  
 end 
 
 #--------------------------------------------------------------------------
 # ● turn_right_90
 #--------------------------------------------------------------------------   
 alias diagonal_turn_right_90 turn_right_90
  def turn_right_90
      if @diagonal and @diagonal_direction != 0
         turn_diagonal_right_90
         return
      end  
      diagonal_turn_right_90
  end
  
 #--------------------------------------------------------------------------
 # ● turn_diagonal_right_90
 #--------------------------------------------------------------------------    
  def turn_diagonal_right_90
      case @diagonal_direction
         when 1;  turn_upper_left
         when 3;  turn_lower_left
         when 7;  turn_upper_right
         when 9;  turn_lower_right
      end
  end
    
 #--------------------------------------------------------------------------
 # ● turn_left_90
 #--------------------------------------------------------------------------    
  alias diagonal_turn_left_90 turn_left_90
  def turn_left_90
      if @diagonal and @diagonal_direction != 0
         turn_diagonal_left_90
         return 
      end
      diagonal_turn_left_90
  end  
    
 #--------------------------------------------------------------------------
 # ● turn_diagonal_left_90
 #--------------------------------------------------------------------------    
  def turn_diagonal_left_90
      case @diagonal_direction
         when 1;  turn_lower_right
         when 3;  turn_upper_right
         when 7;  turn_lower_left
         when 9;  turn_upper_left
      end
  end     
    
  #--------------------------------------------------------------------------
  # ● diagonal_turn_180
  #--------------------------------------------------------------------------
  alias diagonal_turn_180 turn_180
  def turn_180  
      if @diagonal and @diagonal_direction != 0
         turn_diagonal_180 
         return
      end
      diagonal_turn_180
  end
  
 #--------------------------------------------------------------------------
 # ● turn_diagonal_180 
 #--------------------------------------------------------------------------    
  def turn_diagonal_180 
      case @diagonal_direction
         when 1;  turn_upper_right
         when 3;  turn_upper_left
         when 7;  turn_lower_right
         when 9;  turn_lower_left
      end
  end  
    
 #--------------------------------------------------------------------------
 # ● turn_random
 #--------------------------------------------------------------------------    
  alias diagonal_turn_random turn_random
  def turn_random
      if @diagonal 
         turn_diagonal_random
         return 
      end  
      diagonal_turn_random 
  end  
  
 #--------------------------------------------------------------------------
 # ● turn_diagonal_random
 #--------------------------------------------------------------------------    
  def turn_diagonal_random
      case rand(8)
          when 0;  set_direction(8) 
          when 1;  set_direction(6) 
          when 2;  set_direction(4) 
          when 3;  set_direction(2) 
          when 4;  turn_lower_left  
          when 5;  turn_lower_right
          when 6;  turn_upper_left  
          when 7;  turn_upper_right
      end
  end 
end    

#===============================================================================
# ■ Game_Player
#===============================================================================
class Game_Player < Game_Character
  
  #--------------------------------------------------------------------------
  # ● Move By Input
  #--------------------------------------------------------------------------    
#~   alias diagonal_move_by_input move_by_input
#~   def move_by_input
#~       if XAS_SYSTEM::PLAYER_DIAGONAL_MOVEMENT 
#~          player_diagonal_move_by_input
#~         # update_sprite_diagonal
#~          update_return_direction
#~          return
#~       end
#~       diagonal_move_by_input
#~   end   
  def move_by_input
    if self.battler.state_confuse
      if XAS_SYSTEM::PLAYER_DIAGONAL_MOVEMENT 
         player_diagonal_move_by_input_mirror
        # update_sprite_diagonal
         update_return_direction
         return
      end
      return if !movable? || $game_map.interpreter.running?
      move_mirror(Input.dir4) if Input.dir4 > 0
    elsif self.battler.state_c_confuse
      if XAS_SYSTEM::PLAYER_DIAGONAL_MOVEMENT 
        player_diagonal_move_by_input_c_random
        update_return_direction
        return
      end
      return if !movable? || $game_map.interpreter.running?
      move_chance_random(Input.dir4) if Input.dir4 > 0
    elsif self.battler.state_stop
      return
    else
      if XAS_SYSTEM::PLAYER_DIAGONAL_MOVEMENT 
         player_diagonal_move_by_input
        # update_sprite_diagonal
         update_return_direction
         return
      end
      return if !movable? || $game_map.interpreter.running?
      move_straight(Input.dir4) if Input.dir4 > 0
    end
    
  end
    
  #--------------------------------------------------------------------------
  # ● Update Sprite Diagonal
  #--------------------------------------------------------------------------        
  def update_sprite_diagonal
      return if @diagonal_direction == 0
      return if self.action != nil
      return if @dash_active
      make_pose("_Diagonal", 2)
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Return Direction
  #--------------------------------------------------------------------------          
  def update_return_direction
      return if XAS_BA::DIAGONAL_DURATION_ENABLE == false
      return if @diagonal_time == 0
      return if moving? or @stop
      @diagonal_time -= 1
      @diagonal_direction = 0 if @diagonal_time == 0
  end
   
  #--------------------------------------------------------------------------
  # ● Player Diagonal Move By Input
  #--------------------------------------------------------------------------      
  def player_diagonal_move_by_input    
      return unless movable?
      return if $game_map.interpreter.running?
      case Input.dir8
           when 1 
               move_diagonal(4, 2)
               unless moving?
                   move_straight(4)
                   move_straight(2)                 
               end  
               @diagonal_direction = 1  
           when 2; move_straight(2)
           when 3
                move_diagonal(6, 2)
                unless moving?
                   move_straight(6)
                   move_straight(2)
                end
                @diagonal_direction = 3 
           when 4;  move_straight(4)
           when 6;  move_straight(6)
           when 7
                 move_diagonal(4, 8)
                 unless moving?
                    move_straight(4)
                    move_straight(8)
                end
                @diagonal_direction = 7
           when 8;  move_straight(8)
           when 9  
                 move_diagonal(6, 8)
                 unless moving?
                    move_straight(6)
                    move_straight(8)
                end
                @diagonal_direction = 9  
      end
  end  
  #--------------------------------------------------------------------------
  # ● Player Diagonal Move By Input (Mirror)
  #--------------------------------------------------------------------------      
  def player_diagonal_move_by_input_mirror
      return unless movable?
      return if $game_map.interpreter.running?
      case Input.dir8
           when 1 
               move_diagonal(6, 8)
               unless moving?
                   move_straight(6)
                   move_straight(8)                 
               end  
               @diagonal_direction = 9  
           when 2; move_straight(8)
           when 3
                move_diagonal(4, 8)
                unless moving?
                   move_straight(4)
                   move_straight(8)
                end
                @diagonal_direction = 7 
           when 4;  move_straight(6)
           when 6;  move_straight(4)
           when 7
                 move_diagonal(6, 2)
                 unless moving?
                    move_straight(6)
                    move_straight(2)
                end
                @diagonal_direction = 3
           when 8;  move_straight(2)
           when 9  
                 move_diagonal(4, 2)
                 unless moving?
                    move_straight(4)
                    move_straight(2)
                end
                @diagonal_direction = 1  
      end
  end  
  #--------------------------------------------------------------------------
  # ● Move By Input (Mirror)
  #--------------------------------------------------------------------------      
  def move_by_input_mirror
    return if !movable? || $game_map.interpreter.running?
    move_mirror(Input.dir4) if Input.dir4 > 0
  end
  #--------------------------------------------------------------------------
  # ● Player Diagonal Move By Input (Random)
  #--------------------------------------------------------------------------      
  def player_diagonal_move_by_input_c_random
      return unless movable?
      return if $game_map.interpreter.running?
      case Input.dir8
           when 1; move_random
           when 2; move_random
           when 3; move_random
           when 4; move_random
           when 6; move_random
           when 7; move_random
           when 8; move_random
           when 9; move_random
      end
  end  
  #--------------------------------------------------------------------------
  # ● Move By Input (Chance Random)
  #--------------------------------------------------------------------------      
  def move_by_input_c_random
    return if !movable? || $game_map.interpreter.running?
    move_c_random(Input.dir4) if Input.dir4 > 0
  end

end


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ MOVEMENT - FORCE ACTION
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game Character
#===============================================================================
class Game_Character < Game_CharacterBase 
  
  #--------------------------------------------------------------------------
  # ● moving 2? 
  #--------------------------------------------------------------------------  
  def moving2?
      @real_x != @x || @real_y != @y
  end   
  
  #--------------------------------------------------------------------------
  # ● Can Force Action?
  #--------------------------------------------------------------------------          
  def can_force_action?
      return false if @force_action_times  == 0
      return false if self.moving2?
      return false if self.jumping?
      return false if self.knockbacking?
      return false if self.stop
      return false if @fall
      return true
  end
    
  #--------------------------------------------------------------------------
  # ● Update Force Action
  #--------------------------------------------------------------------------        
  def update_force_action
      @force_action_times -= 1
      execute_force_action
      execute_force_action_tool_effect if @tool_id > 0 and @tool_effect != "" 
      reset_auto_action if @force_action_times == 0 
      guide_duration
  end 
  
  #--------------------------------------------------------------------------
  # ● Execute Force Action
  #--------------------------------------------------------------------------          
  def execute_force_action
      case @force_action
        when "Forward" 
            move_forward
        when "Backward" 
            move_backward
        when "Toward Player"   
            move_toward_player 
        when "Move Left"    
            move_straight(4)
        when "Move Right"
            move_straight(6)
        when "Move Up"    
            move_straight(8)
        when "Move Down"
            move_straight(2)
        when "All Shoot"  
              if self.action != nil
                 turn_right_45
                 self.shoot(self.action.id) unless @force_action_times == 0
              end
        when "Four Shoot"  
              if self.action != nil
                 turn_right_90
                 self.shoot(self.action.id) unless @force_action_times == 0
              end               
        when "Three Shoot"  
              if self.action != nil
                 case @force_action_times
                     when 2
                       turn_right_45
                     when 1
                       turn_left_90
                     when 0
                       turn_right_45
                 end  
                 self.shoot(self.action.id) unless @force_action_times == 0
              end       
        when "Two Shoot"  
              if self.action != nil
                 turn_180
                 self.shoot(self.action.id) unless @force_action_times == 0
               end   
        when "Guide"
          if self.action != nil
            move_toward_player
          end
        end
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute Force Action Tool Effect
  #--------------------------------------------------------------------------
  def execute_force_action_tool_effect 
      action_effect_during_move     
      action_effect_after_move if @force_action_times == 0
  end  
  
  #--------------------------------------------------------------------------
  # ● Auto Action Effect During Move
  #--------------------------------------------------------------------------            
  def reset_auto_action  
      @force_action = ""
      @force_action_times = 0
      @anime_count = 0
  end
  
  #--------------------------------------------------------------------------
  # ● Action Effect During Move
  #--------------------------------------------------------------------------          
  def action_effect_during_move  
      if @tool_effect == "Boomerang" and @force_action == "Toward Player"  
         if @x == $game_player.x and @y == $game_player.y  
            self.action.duration = 15
            @force_action_times = 0
            @force_action_type = ""            
          end 
      end
  end  

  #--------------------------------------------------------------------------
  # ● Action Effect After Move
  #--------------------------------------------------------------------------            
  def action_effect_after_move
      if @tool_effect == "Boomerang"
         @force_action_times = 30
         @force_action = "Toward Player"   
         @move_frequency = 6
         @move_speed = 5.5           
      end     
  end      
  
  def guide_duration
    if @tool_effect == "Guide"
      @force_action_times = 30
    end
  end
  
end  


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ MOVEMENT - EXTRA MOVEMENT
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game Character
#===============================================================================
class Game_Character < Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # ● Check XY
  #--------------------------------------------------------------------------      
  def check_xy
      @pre_x = @x
      @pre_y = @y
  end    
 
  #--------------------------------------------------------------------------
  # ● Turn Reverse
  #--------------------------------------------------------------------------          
  def turn_reverse(dir)
      case dir     
        when 2; set_direction(8)
        when 4; set_direction(6)
        when 6; set_direction(4)
        when 8; set_direction(2)
      end    
  end
  
  #--------------------------------------------------------------------------
  # ● Org Here
  #--------------------------------------------------------------------------        
  def org_here
      @orig_pos_x = @x
      @orig_pos_y = @y
  end  
  
  #--------------------------------------------------------------------------
  # ● return_org
  #--------------------------------------------------------------------------          
  def return_org(type = 0)
      if type == 1
         moveto(@orig_pos_x,@orig_pos_x) 
      else  
         jump(0,0)
      end
      @x = @orig_pos_x
      @y = @orig_pos_y
  end  
  
  #--------------------------------------------------------------------------
  # ● Dual Switch
  #--------------------------------------------------------------------------    
  def dual_switch(switch_on, switch_off,percentage = 100)
      enable_per = rand(100)
      if enable_per <= percentage 
         $game_switches[switch_on] = true    
         $game_switches[switch_off] = false
         $game_map.need_refresh = true
      end   
  end   
  
  #--------------------------------------------------------------------------
  # ● Move Forward 2
  #--------------------------------------------------------------------------  
  def move_forward2
      return if moving2?
      move_forward
  end  
  
  #--------------------------------------------------------------------------
  # ● Bounce Direction
  #--------------------------------------------------------------------------  
  def bounce_direction
      @diagonal = true
      turn_random  
  end
  
  #--------------------------------------------------------------------------
  # ● Turn_back
  #--------------------------------------------------------------------------            
  def turn_back
      if @diagonal_direction != 0
         case @diagonal_direction
              when 1
                turn_upper_right
              when 3
                turn_upper_left
              when 7
                turn_lower_right 
              when 9         
                turn_lower_left
         end
      else
          case @direction
               when 2;   set_direction(8) 
               when 4;   @direction = 6#move_straight(6)#set_direction(6) 
               when 6;   set_direction(4) 
               when 8;   set_direction(2) 
          end
      end     
  end  
  
  #--------------------------------------------------------------------------
  # ● Jump_high
  #--------------------------------------------------------------------------
  def jump_high(x_plus,y_plus,high = 10)    
      @x += x_plus
      @y += y_plus
      distance = Math.sqrt(x_plus * x_plus + y_plus * y_plus).round
      @jump_peak = high + distance - @move_speed
      @jump_count = @jump_peak * 2
      @stop_count = 0
      straighten
  end
  
  #--------------------------------------------------------------------------
  # ● Passable Temp
  #--------------------------------------------------------------------------    
 def passable_temp_id?(x, y)
     return false unless $game_map.valid?(x, y)    
     return true if @through or debug_through?     
     return false unless map_passable?(x, y,@direction)         
     return false if collide_with_characters_temp_id?(x, y) 
     return true                                   
  end
  
  #--------------------------------------------------------------------------
  # ● Collide With Characters
  #--------------------------------------------------------------------------      
  def collide_with_characters_temp_id?(x, y)
      for event in $game_map.events_xy(x, y)         
          unless event.through or event.battler != nil    
             return true if self.is_a?(Game_Event)       
             return true if event.priority_type >= 1     
          end
      end
      return false
  end  

  #--------------------------------------------------------------------------
  # ● Force Move Route
  #--------------------------------------------------------------------------
  alias x_force_move_route force_move_route
  def force_move_route(move_route)
      if self.battler != nil and self.is_a?(Game_Event)
         return
      end  
      x_force_move_route(move_route)
  end  
end  


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ MOVEMENT - PLAYER COMMANDS
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#==============================================================================
# ■ Game_Player 
#==============================================================================
class Game_Player < Game_Character
  include XAS_BUTTON
  
  #--------------------------------------------------------------------------
  # ● Update Action Command
  #--------------------------------------------------------------------------  
  def update_action_command
      update_check_battler_equipment if can_check_battler_equipment?
      update_dash_button
      update_auto_target_shoot
      update_combo_time
      update_action_1_button
      update_action_2_button
      update_skill_button
      update_item_button
      update_item_1_button
      update_item_2_button
      update_item_3_button
      update_item_4_button
      update_item_5_button
      update_item_6_button
      update_item_7_button
      update_item_8_button
      update_item_9_button
      update_item_0_button
      update_change_leader_button
      update_charge_button
  end  

  #--------------------------------------------------------------------------
  # ● Can Use Command?
  #--------------------------------------------------------------------------      
  def can_use_command?
      return false if $game_map.interpreter.running?
      return false if $game_message.visible
      return false if self.battler == nil
      return false if self.action != nil
      return false if self.knockbacking?      
      return false if @stop
      return true
  end    
  
  #--------------------------------------------------------------------------
  # ● Update Check Battler Equipment
  #--------------------------------------------------------------------------      
  def update_check_battler_equipment
  
  end  
  
  #--------------------------------------------------------------------------
  # ● Can Check Battler Equipment
  #--------------------------------------------------------------------------        
  def can_check_battler_equipment?
      if self.battler.old_equipment_id[0] != self.battler.equips[0] or
         self.battler.old_equipment_id[1] != self.battler.equips[1] or
         self.battler.old_equipment_id[2] != self.battler.equips[2] or
         self.battler.old_equipment_id[3] != self.battler.equips[3] or
         self.battler.old_equipment_id[4] != self.battler.equips[4]
         self.battler.old_equipment_id[0] = self.battler.equips[0]
         self.battler.old_equipment_id[1] = self.battler.equips[1]
         self.battler.old_equipment_id[2] = self.battler.equips[2]
         self.battler.old_equipment_id[3] = self.battler.equips[3]
         self.battler.old_equipment_id[4] = self.battler.equips[4]      
         return true
      end   
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Update Charge Button
  #--------------------------------------------------------------------------    
  def update_charge_button
      return unless can_charge_command?
      if Input.press?(ACTION_1_BUTTON) and ENABLE_ACTION_1_BUTTON
         update_charge_effect(0)
         reset_charge_temp if Input.press?(ACTION_2_BUTTON) and ENABLE_ACTION_2_BUTTON
      elsif Input.press?(ACTION_2_BUTTON) 
         update_charge_effect(1)
         reset_charge_temp if Input.press?(ACTION_1_BUTTON)
      else
         if self.battler.x_charge_action[2] >= self.battler.x_charge_action[1]
            self.shoot(self.battler.x_charge_action[0])
         end
        reset_charge_temp
      end  
  end

  #--------------------------------------------------------------------------
  # ● Update Charge Effect
  #--------------------------------------------------------------------------        
  def update_charge_effect(type)
      if self.battler.x_charge_action[2] == 0
         return unless equipped_charge_action?(type)
      end  
      if self.battler.x_charge_action[2] < self.battler.x_charge_action[1] 
         self.battler.x_charge_action[2] += 1 
      end
      self.battler.x_charge_action[3] += 1
      if self.battler.x_charge_action[3] > XAS_ANIMATION::LOOP_ANIMATIONS_SPEED
         self.battler.x_charge_action[3] = 0
         if self.battler.x_charge_action[2] < self.battler.x_charge_action[1]
            self.animation_id = XAS_ANIMATION::CHARGE_ANIMATION1_ID
         else
            self.animation_id = XAS_ANIMATION::CHARGE_ANIMATION2_ID
         end  
      end
  end
  
  #--------------------------------------------------------------------------
  # ● Equipped Charge Action
  #--------------------------------------------------------------------------          
  def equipped_charge_action?(type)
      case type
         when 0
           weapon = self.battler.equips[0]
         when 1
           weapon = self.battler.equips[1] 
      end
      if weapon == nil
         return false 
         reset_charge_temp
      end
      if weapon.note =~ /<Charge Action = (\d+) - (\d+)>/   
         self.battler.x_charge_action[0] = $1.to_i rescue 0#Skill ID
         self.battler.x_charge_action[1] = $2.to_i rescue 0#Max Time
         self.battler.x_charge_action[2] = 0#Current Time
         self.battler.x_charge_action[3] = 0#Loop Anime Time
         return true
      end            
      return false    
      reset_charge_temp
  end
  
  #--------------------------------------------------------------------------
  # ● Update Combo Time
  #--------------------------------------------------------------------------        
  def update_combo_time
      return if self.battler.x_combo[2] == 0
      self.battler.x_combo[2] -= 1
      if self.battler.x_combo[2] == 0
         self.battler.x_combo[0] = 0
         self.battler.x_combo[1] = -1
      end   
  end  
  
  #--------------------------------------------------------------------------
  # ● Can Use Weapon Command?
  #--------------------------------------------------------------------------    
  def can_use_weapon_command?
      return false if $game_system.command_enable == false
      return false unless ENABLE_ACTION_1_BUTTON
      return false if self.battler.shield
      return false if self.battler.cast_action[4] > 0
      return false if self.battler.x_charge_action[2] > 0
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● Can Use Shield Command?
  #--------------------------------------------------------------------------      
  def can_use_shield_command?
      return false if $game_system.command_enable == false
      return false unless ENABLE_ACTION_2_BUTTON
      return false if self.battler.equips[1] == nil
      return false if self.battler.equips[1].id == 0
      return false if self.battler.cast_action[4] > 0
      return false if self.battler.x_charge_action[2] > 0
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● Can Use Skill Command?
  #--------------------------------------------------------------------------    
  def can_use_skill_command? 
      return false if $game_system.command_enable == false
      return false unless ENABLE_SKILL_BUTTON
      return false if self.battler.shield
      return false if self.battler.cast_action[4] > 0
      return false if self.battler.x_charge_action[2] > 0
      return true
  end    
  
  #--------------------------------------------------------------------------
  # ● Can Use Item Command?
  #--------------------------------------------------------------------------    
  def can_use_item_command?
      return false if $game_system.command_enable == false
      return false unless ENABLE_ITEM_BUTTON
      return false if self.battler.shield    
      return false if self.battler.cast_action[4] > 0
      return false if self.battler.x_charge_action[2] > 0
      return true
  end      
  
  #--------------------------------------------------------------------------
  # ● Can Charge Command
  #--------------------------------------------------------------------------      
  def can_charge_command?
      return false if $game_system.command_enable == false
      return false if self.battler.cast_action[4] > 0
      return false if self.battler.shield      
      return true
  end   
  
  #--------------------------------------------------------------------------
  # ● Can Use Change Leader Command?
  #--------------------------------------------------------------------------      
  def can_use_change_leader_command?
      return false unless ENABLE_CHANGE_LEADER_BUTTON
      return false if self.battler.shield    
      return false if self.battler.cast_action[4] > 0
      return false if self.battler.x_charge_action[2] > 0
      return false if $game_temp.change_leader_wait_time > 0
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● State_Seal Command
  #--------------------------------------------------------------------------        
  def state_seal_command?(type)
      seal = false
      case type  
         when 0
            seal = true if self.battler.state_mute
            seal = true if self.battler.state_seal_attack
         when 1
            seal = true if self.battler.state_mute
            seal = true if self.battler.state_seal_attack
         when 2
            seal = true if self.battler.state_mute
            seal = true if self.battler.state_seal_skill
         when 3  
            seal = true if self.battler.state_mute   
            seal = true if self.battler.state_seal_item
      end
      if seal
         seal_effect 
         return true
      end  
      return false      
  end  
  
  #--------------------------------------------------------------------------
  # ● Check Equipped Action
  #--------------------------------------------------------------------------    
  def check_equipped_action(command_type, val=0)
      case command_type
         when 0 # Weapon 1
            weapon = self.battler.equips[0]
            if weapon == nil 
               self.battler.x_action1_id = 0
               return 
            end
            weapon.note =~ /<Action ID = (\d+)>/   
            action_id =  $1.to_i
            action_id = 0 if action_id == nil 
            self.battler.x_action1_id = action_id
         when 1 # Weapon 2
            weapon = self.battler.equips[1]
            if weapon == nil 
               self.battler.x_action2_id = 0
               return 
            end   
            weapon.note =~ /<Action ID = (\d+)>/
            action_id =  $1.to_i
            action_id = 0 if action_id == nil             
            self.battler.x_action2_id = action_id
         when 2 # Skill   
            
         when 3 # Item 
           case val
             when 0
               item_id = $data_items[self.battler.item_id]
             when 1
               item_id = $data_items[self.battler.item_extra_1]
             when 2
               item_id = $data_items[self.battler.item_extra_2]
             when 3
               item_id = $data_items[self.battler.item_extra_3]
             when 4
               item_id = $data_items[self.battler.item_extra_4]
             when 5
               item_id = $data_items[self.battler.item_extra_5]
             when 6
               item_id = $data_items[self.battler.item_extra_6]
             when 7
               item_id = $data_items[self.battler.item_extra_7]
             when 8
               item_id = $data_items[self.battler.item_extra_8]
             when 9
               item_id = $data_items[self.battler.item_extra_9]
             when 10
               item_id = $data_items[self.battler.item_extra_0]
           end
           if item_id == nil
             self.battler.x_item_id = 0
             return
           end
           item_id.note =~ /<Action ID = (\d+)>/
           action_id =  $1.to_i
           action_id = 0 if action_id == nil
           self.battler.x_item_id = action_id
      end     
  end
    
  #--------------------------------------------------------------------------
  # ● Execute Combo
  #--------------------------------------------------------------------------        
  def execute_combo?(type)  
      if type == self.battler.x_combo[1] and self.battler.x_combo[0] != 0
         return if state_seal_command?(type)        
         self.shoot(self.battler.x_combo[0])
         self.battler.x_combo[1] = type 
         return true
      end  
      self.battler.x_combo[0] = 0
      self.battler.x_combo[1] = type
      self.battler.x_combo[2] = 0
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Update Change Leader Button
  #--------------------------------------------------------------------------        
  def update_change_leader_button
      if Input.trigger?(CHANGE_LEADER_BUTTON)
         return unless can_use_change_leader_command?
         change_leader     
      end 
  end
  
  #--------------------------------------------------------------------------
  # ● Update Action 1 Button
  #--------------------------------------------------------------------------      
  def update_action_1_button
      if Input.trigger?(ACTION_1_BUTTON)
         type = 0
         return unless can_use_weapon_command?
         return if execute_combo?(type)
         check_equipped_action(type)
         action_id = self.battler.x_action1_id
         return if action_id == 0 
         return if state_seal_command?(type)
         self.shoot(action_id)
      end    
  end
    
  #--------------------------------------------------------------------------
  # ● Update Action 2 Button
  #--------------------------------------------------------------------------    
  def update_action_2_button
      if Input.trigger?(ACTION_2_BUTTON)
         if self.battler.equips[1].is_a?(RPG::Weapon)
            type = 1 
            return unless can_use_weapon_command?
            return if execute_combo?(type)
            check_equipped_action(type)
            action_id = self.battler.x_action2_id
            return if action_id == 0 
            return if state_seal_command?(type)            
            self.shoot(action_id)
            return
         end   
      end         
      update_shield_button
  end
  
  #--------------------------------------------------------------------------
  # ● Update Shield Button
  #--------------------------------------------------------------------------        
  def update_shield_button
      if Input.press?(ACTION_2_BUTTON) 
         if can_use_shield_command? 
            unless self.battler.shield  
                shield = self.battler.equips[1]
                if shield.note =~ /<Action>/
                   if shield.note =~ /<Pose = (\w+)>/
                      make_pose($1.to_s, 2) 
                   end
                else   
                   self.battler.shield = false
                   return
                end
            end 
            self.x_pose_duration = 2
            self.battler.shield = true 
            update_shield_diretion_button
         else
            self.battler.shield = false
         end  
      else   
         self.battler.shield = false
      end       
  end
  
  #--------------------------------------------------------------------------
  # ● update_shield_direction_button
  #--------------------------------------------------------------------------          
  def update_shield_diretion_button 
      return if @direction_fix
      case Input.dir4
         when 2;  set_direction(2)   
         when 4;  set_direction(4)   
         when 6;  set_direction(6)   
         when 8;  set_direction(8)   
      end
  end
  
  #--------------------------------------------------------------------------
  # ● Update Skill Button
  #--------------------------------------------------------------------------      
  def update_skill_button
#~       if Input.trigger?(SKILL_BUTTON)
#~          type = 2
#~          return unless can_use_skill_command?
#~          return if execute_combo?(type)
#~          check_equipped_action(type)
#~          action_id = self.battler.skill_id
#~          return if action_id == 0 
#~          return if state_seal_command?(type)         
#~          self.shoot(action_id)
#~       end    
  end
  
  #--------------------------------------------------------------------------
  # ● Update Item Button
  #--------------------------------------------------------------------------      
  def update_item_button
#~       if Input.repeat?(ITEM_BUTTON) #trigger?(ITEM_BUTTON)
#~          type = 3         
#~          return unless can_use_item_command?
#~          return if execute_combo?(type)
#~          check_equipped_action(type)
#~          action_id = self.battler.x_item_id
#~          return if action_id == 0 
#~          return if state_seal_command?(type)         
#~          self.shoot(action_id)
#~       end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_1_button
      if Input.repeat?(ITEM_BUTTON_1)
         self.battler.item_or_skill_1 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 1)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_1
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_2_button
      if Input.repeat?(ITEM_BUTTON_2)
         self.battler.item_or_skill_2 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 2)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_2
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_3_button
      if Input.repeat?(ITEM_BUTTON_3)
         self.battler.item_or_skill_3 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 3)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_3
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_4_button
      if Input.repeat?(ITEM_BUTTON_4)
         self.battler.item_or_skill_4 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 4)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_4
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_5_button
      if Input.repeat?(ITEM_BUTTON_5)
         self.battler.item_or_skill_5 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 5)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_5
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_6_button
      if Input.repeat?(ITEM_BUTTON_6)
         self.battler.item_or_skill_6 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 6)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_6
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_7_button
      if Input.repeat?(ITEM_BUTTON_7)
         self.battler.item_or_skill_7 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 7)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_7
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_8_button
      if Input.repeat?(ITEM_BUTTON_8)
         self.battler.item_or_skill_8 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 8)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_8
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_9_button
      if Input.repeat?(ITEM_BUTTON_9)
         self.battler.item_or_skill_9 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 9)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_9
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Extra Button
  #--------------------------------------------------------------------------      
  def update_item_0_button
      if Input.repeat?(ITEM_BUTTON_0)
         self.battler.item_or_skill_0 == 0 ? type = 3 : type = 2
         if type == 3
           return unless can_use_item_command?
         else
           return unless can_use_skill_command?
         end
         return if execute_combo?(type)
         check_equipped_action(type, 10)
         if type == 3
           action_id = self.battler.x_item_id
         else
           action_id = self.battler.item_extra_0
         end
         return if action_id == 0 
         return if state_seal_command?(type)         
         self.shoot(action_id)
      end   
  end
  
  #--------------------------------------------------------------------------
  # ● Update Auto Target Shoot
  #-------------------------------------------------------------------------- 
  def update_auto_target_shoot
      return if $game_temp.xas_target_time == 0
      return if $game_temp.xas_target_shoot_id == 0
      return if $game_temp.xas_target_x == 0 and $game_temp.xas_target_y == 0   
      $game_temp.xas_target_time -= 1
      if $game_temp.xas_target_time == 0
         self.shoot($game_temp.xas_target_shoot_id) 
         $game_temp.xas_target_shoot_id = 0
      end   
  end   
  
 #--------------------------------------------------------------------------
 # ● Dash?
 #--------------------------------------------------------------------------            
 alias x_dash dash?
 def dash?   
     return false if XAS_SYSTEM::DASH_SYSTEM 
     x_dash
 end 

 #--------------------------------------------------------------------------
 # ● Can Dash?
 #--------------------------------------------------------------------------              
 def can_dash?
     return false unless XAS_BUTTON::ENABLE_DASH_BUTTON
     return false if self.battler.shield
     dash_possible = false
     for i in 0 ... self.battler.equips.size
       next if self.battler.equips[i] == nil
       if self.battler.equips[i].note =~ /<(?:대쉬|Dash)>/
         dash_possible = true
         break
       end
     end
     if self.battler.hp >= self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100 && dash_possible
     return !Input.press?(XAS_BUTTON::DASH_BUTTON) if $game_system.autodash?
     return true if Input.press?(XAS_BUTTON::DASH_BUTTON)
     end
     @dash_active = false
     return false
 end
 
 #--------------------------------------------------------------------------
 # ● Update Dash Command
 #--------------------------------------------------------------------------             
 def update_dash_button
     return unless can_dash?
     @dash_active = true
     @anime_count -= 0.5 if moving? 
     update_dash_sprite_name
 end  
 
 #--------------------------------------------------------------------------
 # ● Update Dash Sprite Name
 #--------------------------------------------------------------------------              
 def update_dash_sprite_name
     make_pose("_Dash", 2) 
 end
 
end 


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ TOOL - INITIALIZE
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game_Map
#===============================================================================
class Game_Map
  
  attr_accessor :need_refresh_token

  #--------------------------------------------------------------------------
  # ● need_add_tokens 
  #--------------------------------------------------------------------------  
  def need_add_tokens
      @need_add_tokens = [] if @need_add_tokens == nil
      return @need_add_tokens
  end
  
  #--------------------------------------------------------------------------
  # ● need_remove_tokens 
  #--------------------------------------------------------------------------
  def need_remove_tokens
      @need_remove_tokens = [] if @need_remove_tokens == nil
      return @need_remove_tokens
  end
  
  #--------------------------------------------------------------------------
  # ● add_token 
  #--------------------------------------------------------------------------
  def add_token(token_event)
      $game_temp.tool_event = [] if $game_temp.tool_event == nil
      $game_temp.tool_event.push(token_event)
      self.need_add_tokens.push(token_event)
      self.need_refresh_token = true
  end
  
  #--------------------------------------------------------------------------
  # ● remove_token
  #--------------------------------------------------------------------------
  def remove_token(token_event)
      @events.delete(token_event.id)
      self.need_remove_tokens.push(token_event)
      self.need_refresh_token = true
  end
 
  #--------------------------------------------------------------------------
  # ● clear_tokens 
  #--------------------------------------------------------------------------
  def clear_tokens
      $game_system.tools_on_map.clear
      $game_system.tools_on_map = []
      for event in @events.values.dup
          remove_token(event) if event.is_a?(Token_Event)
      end
      channels = ["A", "B", "C", "D"]
      for id in 1001..(token_id_shift - 1)
          for a in channels
              key = [self.map_id, id, a]
              $game_self_switches.delete(key)
          end
      end
      clear_token_id
  end
    
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------      
  alias x_temp_tool_hash_update update
  def update(main = false)
      x_temp_tool_hash_update(main)
      update_add_tool_hash
  end

  #--------------------------------------------------------------------------
  # ● Update Add Toll Hash
  #--------------------------------------------------------------------------      
  def update_add_tool_hash  
      return if $game_temp.tool_event == nil
      for i in $game_temp.tool_event
          $game_map.events[i.id] = i
          execute_tool_effects_hash(i)
      end  
      $game_temp.tool_event.clear
      $game_temp.tool_event = nil
  end
    
  #--------------------------------------------------------------------------
  # ● Execute Toll Effects Hash
  #--------------------------------------------------------------------------        
  def execute_tool_effects_hash(i)
      
  end  
end

#===============================================================================
# ■ Game_SelfSwitches  
#===============================================================================
class Game_SelfSwitches
  def delete(key)
      @data.delete(key)
  end
end

#===============================================================================
# ■ Game_Map  
#===============================================================================
class Game_Map
    
  attr_accessor :token_id
  
  #--------------------------------------------------------------------------
  # ● token_id_shift 
  #--------------------------------------------------------------------------  
  def token_id_shift
      @token_id  = 1000 if @token_id == nil
      @token_id += 1
      return @token_id
  end

  #--------------------------------------------------------------------------
  # ● clear_token_id 
  #--------------------------------------------------------------------------  
  def clear_token_id
      @token_id = nil
  end
end

#===============================================================================
# ■ XRXS_CTS_RefreshToken 
#===============================================================================
module XRXS_CTS_RefreshToken
  
  #--------------------------------------------------------------------------
  # ● refresh_token
  #--------------------------------------------------------------------------  
  def refresh_token
      for event in $game_map.need_add_tokens
          @character_sprites.push(Sprite_Character.new(@viewport1, event))
      end
      $game_map.need_add_tokens.clear
      for sprite in @character_sprites.dup
          if $game_map.need_remove_tokens.empty?
             break
          end
          if $game_map.need_remove_tokens.delete(sprite.character)
             @character_sprites.delete(sprite)
             sprite.dispose
          end
      end
      $game_map.need_refresh_token = false
  end
end

#===============================================================================
# ■  Spriteset_Map
#===============================================================================
class Spriteset_Map
  include XRXS_CTS_RefreshToken
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------    
  alias x_smap_initialize initialize
  def initialize
      setup_start
      x_smap_initialize
  end
  
  #--------------------------------------------------------------------------
  # ● Setup Start
  #--------------------------------------------------------------------------      
  def setup_start
      $game_player.reset_old_level(true)
  end
  
end

#===============================================================================
# ■ Game_Player
#===============================================================================
class Game_Player < Game_Character

  #--------------------------------------------------------------------------
  # ● x_reserve_transfer
  #--------------------------------------------------------------------------     
  alias x_reserve_transfer reserve_transfer 
  def reserve_transfer(map_id, x, y, direction)
      $game_map.clear_tokens
      if $game_temp.tool_event != nil 
         $game_temp.tool_event.clear
         $game_temp.tool_event = nil
      end   
      x_reserve_transfer(map_id, x, y, direction)
  end
  
end

#===============================================================================
# ■ Token_Event
#===============================================================================
class Token_Event < Game_Event
  
  #--------------------------------------------------------------------------
  # ● Token_Event
  #--------------------------------------------------------------------------
  def initialize(map_id, event)
      event.id = $game_map.token_id_shift
      super
  end
  
  #--------------------------------------------------------------------------
  # ● erase
  #--------------------------------------------------------------------------
  def erase
      super
      $game_map.remove_token(self)
  end
end


#===============================================================================
# ■  XRXS_ActionTemplate
#===============================================================================
module XRXS_ActionTemplate
  map_id = XAS_SYSTEM::ACTION_TEMPLATE_MAP_ID
  map = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
  @@events = map.events
end

#===============================================================================
# ■  Token_Event
#===============================================================================
class Token_Event < Game_Event
  include XRXS_ActionTemplate
end

#===============================================================================
# ■  Game_Temp
#===============================================================================
class Game_Temp
  attr_accessor :active_token
end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ TOOL - SHOOT COMMAND
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ XAS ACTION
#===============================================================================
module XAS_ACTION
  attr_reader   :action
  attr_reader   :erased
  
  #--------------------------------------------------------------------------
  # ● shoot
  #--------------------------------------------------------------------------
  def shoot(action_id = 0)
    self.delect_swi = [] if self.delect_swi == nil
    self.delect_swi.delete(action_id) if self.delect_swi.include?(action_id)
      return if action_id == 0 
      skill = $data_skills[action_id]
      return unless can_shoot?(skill)
      execute_user_effects(skill)
      execute_call_event(action_id)      
      self.action_attachment(action_id) unless self.is_a?(Token_Bullet)
      execute_set_pose(action_id)
  end
  #--------------------------------------------------------------------------
  # ● Shoot Reset
  #--------------------------------------------------------------------------
  def shoot_reset(action_id = 0)
    return if action_id == 0
    self.delect_swi.delete(action_id) if self.delect_swi.include?(action_id)
  end
  #--------------------------------------------------------------------------
  # ● Shoot Delect
  #--------------------------------------------------------------------------
  def shoot_delect(action_id = 0)
    return if action_id == 0 
    self.delect_swi.push(action_id) unless self.delect_swi.include?(action_id)
  end
  #--------------------------------------------------------------------------
  # ● Can Shoot
  #--------------------------------------------------------------------------    
  def can_shoot?(skill)
      if self.battler == nil and self.tool_id > 0
         @battler = self.action.user.battler
      end  
      return false if self.battler == nil
      return false if skill == nil
      return true if ignore_can_shoot?(skill)
      enough_cost = true
      return false if tools_on_map?(skill.id)      
      if self.battler.state_mute  
         seal_effect 
         return false
      end   
      if self.battler.cast_action[4].between?(1,self.battler.cast_action[1] -1)
         return false 
      end
      return false if check_cast_action?(skill)
      return false if check_auto_target_select?(skill)
      unless enough_skill_cost?(skill)
         Audio.se_play("Audio/SE/" + XAS_SOUND::ACTION_COST , 100, 100) 
         return false 
      end
      return true
  end 
  
  #--------------------------------------------------------------------------
  # ● Ignore Can Shoot?     
  #--------------------------------------------------------------------------                
  def ignore_can_shoot?(skill)
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Tools on Map
  #--------------------------------------------------------------------------              
  def tools_on_map?(skill_id)
      return true if $game_system.tools_on_map.include?(skill_id)
      return false
  end  
  
  #--------------------------------------------------------------------------
  # ● Check Cast Action
  #--------------------------------------------------------------------------            
  def check_cast_action?(skill)
      if self.battler.cast_action[0] != 0
         self.battler.cast_action[0] = 0
         self.battler.cast_action[1] = 0
         self.battler.cast_action[2] = 0
         self.battler.cast_action[3] = 0
         self.battler.cast_action[4] = 0
         return false
      end  
      if skill.note =~ /<Cast Time = (\d+)>/ and
         $game_temp.xas_target_shoot_id == 0 and
         self.force_action_times == 0
         self.battler.cast_action[0] = skill.id
         self.battler.cast_action[1] = $1.to_i rescue 0
         self.battler.cast_action[2] = XAS_ANIMATION::CAST_TIME_ANIMATION_ID
         self.battler.cast_action[3] = 0
         self.battler.cast_action[4] = 0
         self.animation_id = self.battler.cast_action[2]
         return true
      end      
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Check Auto Target Select
  #--------------------------------------------------------------------------          
  def check_auto_target_select?(skill)
      return false if self.is_a?(Game_Event)
      if skill.note =~ /<Auto Target>/
         if $game_temp.xas_target_shoot_id == 0
            $game_temp.xas_target_shoot_id = skill.id
            $game_map.check_events_on_screen
            SceneManager.call(Scene_Target_Select)
            return true 
         end          
      end  
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● enough_skill_cost?
  #--------------------------------------------------------------------------          
  def enough_skill_cost?(skill)
      return false unless enough_mp_cost?(skill)         
      return false unless enough_tp_cost?(skill)      
      return false unless enough_item_cost?(skill)      
      return false unless enough_item_cost2?(skill)
      unless @force_action_times > 0
        unless @force_action == "All Shoot" or @force_action == "Four Shoot" or
          @force_action == "Three Shoot" or @force_action == "Two Shoot"
          self.battler.mp -= (skill.mp_cost * self.battler.mcr).to_i if enough_mp_cost?(skill)
          self.battler.tp -= (skill.tp_cost * self.battler.tcr).to_i if enough_tp_cost?(skill)
        end
      end      
      return true
  end
    
  #--------------------------------------------------------------------------
  # ● Enough MP Cost
  #--------------------------------------------------------------------------        
  def enough_mp_cost?(skill)  
      if @force_action_times > 0
         return true if @force_action == "All Shoot" 
         return true if @force_action == "Four Shoot"  
         return true if @force_action == "Three Shoot" 
         return true if @force_action == "Two Shoot" 
      end
      if self.battler.mp < (skill.mp_cost * self.battler.mcr).to_i
         self.battler.damage = XAS_WORD::NO_MP
         self.battler.damage_pop = true
         return false
      else   
#~          self.battler.mp -= (skill.mp_cost * self.battler.mcr).to_i
         return true
      end
      return true 
  end  
  
  #--------------------------------------------------------------------------
  # ● Enough Item Cost
  #--------------------------------------------------------------------------      
  def enough_item_cost?(skill)
      return true if self.battler.is_a?(Game_Enemy)
      if @force_action_times > 0
         return true if @force_action == "All Shoot"
         return true if @force_action == "Four Shoot"
         return true if @force_action == "Three Shoot"
         return true if @force_action == "Two Shoot" 
      end      
      skill.note =~ /<Item Cost = (\d+)>/
      item_id = $1.to_i
      if item_id != nil and item_id != 0
         item_cost = $data_items[item_id]
         number = $game_party.item_number(item_cost)
         if number == 0 or number == nil
            self.battler.damage = XAS_WORD::NO_ITEM
            self.battler.damage_pop = true
            return false 
         else
            $game_party.lose_item(item_cost, 1, false)
            return true
         end            
      end    
      return true 
  end    
  
  #--------------------------------------------------------------------------
  # ● Enough TP Cost
  #--------------------------------------------------------------------------        
  def enough_tp_cost?(skill)  
      if @force_action_times > 0
         return true if @force_action == "All Shoot" 
         return true if @force_action == "Four Shoot"  
         return true if @force_action == "Three Shoot" 
         return true if @force_action == "Two Shoot" 
      end
      if self.battler.tp < (skill.tp_cost * self.battler.tcr).to_i
         self.battler.damage = XAS_WORD::NO_TP
         self.battler.damage_pop = true
         return false
      else   
#~          self.battler.tp -= (skill.tp_cost * self.battler.tcr).to_i
         return true
      end
      return true 
  end  
  
  #--------------------------------------------------------------------------
  # ● Enough Item Cost 2
  #--------------------------------------------------------------------------      
  def enough_item_cost2?(skill)
      return true if self.battler.is_a?(Game_Enemy)
      if @force_action_times > 0
         return true if @force_action == "All Shoot"
         return true if @force_action == "Four Shoot"
         return true if @force_action == "Three Shoot"
         return true if @force_action == "Two Shoot" 
      end      
      skill.note =~ /<Item Costs = (\d+) - (\d+)>/
      item_id = $1.to_i
      item_num = $2.to_i
      if item_id != nil and item_id != 0
         item_cost = $data_items[item_id]
         number = $game_party.item_number(item_cost)
         if number == 0 or number == nil or number < item_num
            self.battler.damage = XAS_WORD::NO_ITEM
            self.battler.damage_pop = true
            return false 
         else
            $game_party.lose_item(item_cost, item_num, false)
            return true
         end            
      end    
      return true 
  end    
  
  #--------------------------------------------------------------------------
  # ● Execute User Effects
  #--------------------------------------------------------------------------  
  def execute_user_effects(skill)
      self.battler.shield = false
      #Animation
      if skill.note =~ /<Cast Ani = (\d+)>/
         ani_id = $1.to_i     
         if ani_id != nil
            self.animation_id = ani_id
         end   
      end
      if skill.note =~ /<Guide>/
        @force_action = "Guide"
        @force_action_times = 30
        @self_target = 0
        near_check = -1
        for event in $game_map.events.values
          next unless event.battler.is_a?(Game_Enemy)
          next if event.battler.dead?
          next if event.erased
          next if event.battler.invunerable
          next if event.battler.no_damage_pop
          cx = ( event.x - self.x ).abs
          cy = ( event.y - self.y ).abs
          if ( cx * cy ) == 0
            if near_check > cx + cy || near_check < 0
              near_check = ( cx + cy )
              @self_target = event.id
            end
          else
            if near_check > Math.sqrt( ( cx * cx ) + ( cy * cy ) ) || near_check < 0
              near_check = Math.sqrt( ( cx * cx ) + ( cy * cy ) ) 
              @self_target = event.id
            end
          end
          @self_target = -1 if self.battler.is_a?(Game_Enemy)
        end
      end
      unless @force_action_times > 0
          #All Directions
          if skill.note =~ /<All Directions>/
             @force_action = "All Shoot" 
             @force_action_times = 8        
          elsif skill.note =~ /<Four Directions>/
             @force_action = "Four Shoot" 
             @force_action_times = 4       
          elsif skill.note =~ /<Three Directions>/
             @force_action = "Three Shoot" 
             @force_action_times = 3        
          elsif skill.note =~ /<Two Directions>/
             @force_action = "Two Shoot" 
             @force_action_times = 2         
          end  
      end  
  end
    
  #--------------------------------------------------------------------------
  # ● Execute Set Pose
  #--------------------------------------------------------------------------      
  def execute_set_pose(action_id)
      @action.duration = @action.sunflag unless self.is_a?(Token_Bullet)
      make_pose(@action.self_motion, @action.sunflag ) 
      @pattern = 0
      @pattern_count  = 0
      @step_anime = true
      @self_motion = nil      
      self.need_refresh = true if self.is_a?(Game_Player)
  end  
    
  #--------------------------------------------------------------------------
  # ● execute_call_event
  #--------------------------------------------------------------------------  
  def execute_call_event(action_id)
      bullet_token = Token_Bullet.new(self, action_id)
      $game_map.add_token(bullet_token)
      return bullet_token
  end
      
  #--------------------------------------------------------------------------
  # ● action_attachment
  #--------------------------------------------------------------------------
  def action_attachment(action_id)
      @action = Game_Action_XAS.new(self, action_id)
      @action.attachment(action_id)
  end
  
end  


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ TOOL - SHOOT SETTING
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game_Action_XAS
#===============================================================================
class Game_Action_XAS
  
  attr_accessor   :user
  attr_accessor   :id                    
  attr_accessor   :attack_id            
  attr_accessor   :attack_range
  attr_accessor   :attack_range_type
  attr_accessor   :hit_events
  attr_accessor   :now_count
  attr_accessor   :pre_now_count
  attr_accessor   :infinity_duration
  attr_accessor   :duration
  attr_accessor   :blow_power
  attr_accessor   :piercing
  attr_accessor   :ignore_knockback_invincible
  attr_accessor   :target_invunerable_duration
  attr_accessor   :multi_hit
  attr_accessor   :ally_damage
  attr_accessor   :all_damage
  attr_accessor   :sunflag
  attr_accessor   :self_motion
  attr_accessor   :second_animation_id
  attr_accessor   :third_animation_id
  attr_accessor   :attack_range_type
  attr_accessor   :attack_range_plan
  attr_accessor   :blow_power
  attr_accessor   :ignore_guard
  attr_accessor   :user_invincible  
  attr_accessor   :short_range
  attr_accessor   :first_impact_time
  attr_accessor   :animation_time
  attr_accessor   :duration 
  attr_accessor   :item_cost
  attr_accessor   :item_cost_num
  attr_accessor   :hit_shake
  attr_accessor   :hit_hold_target
  attr_accessor   :hit_bounce
  attr_accessor   :sticky
  attr_accessor   :reflectable
  attr_accessor   :can_reflect
  attr_accessor   :attack_id_plan
  attr_accessor   :hit_action
  attr_accessor   :fake_id
  attr_accessor   :impact
  
  #--------------------------------------------------------------------------
  # ● initialize
  #--------------------------------------------------------------------------
  def initialize(user, action_id)
      @user        = user
      @id          = action_id
      @now_count   = 0
      @infinity_duration = false
      @duration    = nil
      @attack_id   = 0
      @attack_range = 0
      @hit_events  = []
      @blow_power  = 0
      @skill = $data_skills[action_id]
      @ignore_knockback_invincible = false
      @multi_hit = false
      @piercing = false
      @all_damage = false
      @ally_damage = false
      @ignore_guard = false
      @sunflag = 10
      @duration = 10
      @self_motion = ""
      @attack_range_type = 1
      @attack_range_plan = 1
      @blow_power = 1
      @first_impact_time  = 0
      @animation_time = []
      @target_invunerable_duration = 10
      @second_animation_id = 0
      @third_animation_id = 0 
      @user_invincible = false
      @short_range = false
      @item_cost = 0
      @item_cost_num = 1
      @hit_shake = false
      @hit_hold_target = false
      @hit_bounce = false
      @sticky = false
      @reflectable = false
      @can_reflect = false
      @hit_action = 0
      @fake_id = false
      @impact = true
  end
  
  #--------------------------------------------------------------------------
  # ● attachment 
  #--------------------------------------------------------------------------
  def attachment(action_id)
      @attack_id_plan = [action_id]
      if @skill.note =~ /<Sunflag = (\d+)>/
         @sunflag = $1.to_i
      end
      if @skill.note =~ /<Duration = (\d+)>/   
         @duration = $1.to_i
      end
      if @skill.note =~ /<Infinity Duration>/
         @infinity_duration = true
      end
      if @skill.note =~ /<Pose = (\S+)>/   
         @self_motion = $1.to_s
      end
      if @skill.note =~ /<Area = (\w+)>/ 
         case $1
            when "CROSS"   
               area = 7
            when "WALL" 
               area = 6        
            when "FRONTRHOMBUS"  
               area = 5
            when "FRONTSQUARE"
               area = 4
            when "LINE"
               area = 3
            when "SQUARE"
               area = 2               
            else   
               area = 1 
         end     
         @attack_range_type = area
       end
      if @skill.note =~ /<Range = (\d+)>/   
         @attack_range_plan = [$1.to_i]
      end
      if @skill.note =~ /<Blow Power = (\d+)>/  
         @blow_power = $1.to_i
      end   
      if @skill.note =~ /<Impact Time = (\d+)>/   
         @first_impact_time = $1.to_i

       end   
      if @skill.note =~ /<Ani Time = (\d+) - (\d+)>/   
         @animation_time[0] = $1.to_i
         @animation_time[1] = $2.to_i
      end
      if @skill.note =~ /<Target Invunerable = (\d+)>/
         @target_invunerable_duration = $1.to_i
      end  
      if @skill.note =~ /<Tool Hit Ani = (\d+)>/       
         @second_animation_id = $1.to_i
      end         
      if @skill.note =~ /<User Hit Ani = (\d+)>/       
         @third_animation_id = $1.to_i
      end   
      if @skill.note =~ /<Item Cost = (\d+)>/    
         @item_cost = $1.to_i
      end         
      if @skill.note =~ /<Item Costs = (\d+) - (\d+)>/    
         @item_cost = $1.to_i
         @item_cost_num = $2.to_i
      end         
      if @skill.note =~ /<Link Action ID = (\d+)>/    
         if user.battler != nil
            user.battler.x_combo[0] = $1.to_i
            user.battler.x_combo[2] = @sunflag + 20
         end
      else     
         if user.battler != nil
            user.battler.x_combo[0] = 0
            user.battler.x_combo[1] = 0
            user.battler.x_combo[2] = 0
         end            
      end   
      if @skill.note =~ /<Hit Action ID = (\d+)>/
         @hit_action = $1.to_i
      end
      if @skill.note =~ /<Ignore Knockback>/
         @ignore_knockback_invincible = true
      end       
      if @skill.note =~ /<Multi Hit>/
         @multi_hit = true  
      end         
      if @skill.note =~ /<Piercing>/
         @piercing = true 
      end
      if @skill.note =~ /<All Damage>/
         @all_damage = true 
      end
      if @skill.note =~ /<Ally Damage>/
         @ally_damage = true 
      end       
      if @skill.note =~ /<User Invincible>/
         @user_invincible = true
      end       
      if @skill.note =~ /<Ignore Guard>/
         @ignore_guard = true
      end       
      if @skill.note =~ /<One Action>/
         unless $game_system.tools_on_map.include?(action_id)   
                $game_system.tools_on_map.push(action_id)
         end
      end       
      if @skill.note =~ /<Shake>/
         @hit_shake = true
      end
      if @skill.note =~ /<User Range>/
         @short_range = true
      end      
      if @skill.note =~ /<Hit Hold Target>/
         @hit_hold_target = true
      end        
      if @skill.note =~ /<Hit Sticky Target>/
         @sticky = true
      end        
      if @skill.note =~ /<Hit Bounce Direction>/
         @hit_bounce = true
      end   
      if @skill.note =~ /<Reflectable>/
         @reflectable = true
      end        
      if @skill.note =~ /<Can Reflect>/
         @can_reflect = true
      end  
      if @skill.note =~ /<Disable Hit>/
         @impact = false
      end
      @sunflag = 1 if @sunflag <= 0 
  end
  
  #--------------------------------------------------------------------------
  # ● update
  #--------------------------------------------------------------------------
  def update
      @first_impact_time -= 1 if @first_impact_time > 0
      if @attack_id_plan != nil
         id = @attack_id_plan[@now_count]
         unless id.nil? 
           @attack_id = id
           @hit_events.clear
           @hit_events.push(self.user) unless @all_damage or @ally_damage or self.user.battler.state_suicide
         end
      end
      if @attack_range_plan != nil
         range = @attack_range_plan[@now_count]
         @attack_range = range unless range.nil?
      end
      self.user.delect_swi = [] if self.user.delect_swi == nil
      @infinity_duration = false if self.user.delect_swi.include?(@attack_id)
      @now_count += 1 unless @infinity_duration
  end  
  
  #--------------------------------------------------------------------------
  # ● done? 
  #--------------------------------------------------------------------------
  def done?
      return (self.duration.to_i > 0 and self.now_count >= self.duration)
  end
end

#===============================================================================
# ■ Token_Bullet  
#===============================================================================
class Token_Bullet < Token_Event
include XRXS_ActionTemplate
  #--------------------------------------------------------------------------
  # ● initialize 
  #--------------------------------------------------------------------------
  def initialize(user, action_id)
      event_id = action_id
      skill = $data_skills[action_id]
      if skill.note =~ /<Event ID = (\d+)>/
         event_id = $1.to_i
      end  
      original_event = @@events[event_id]
      if original_event == nil
         msgbox("There's no Event ID " + event_id.to_s + " on Tool Map!") 
         SceneManager.exit
         return 
      end  
      event = original_event.dup 
      event.x = user.x
      event.y = user.y
      pre_direction = event.pages[0].graphic.direction
      event.pages[0].graphic.direction = user.direction
      @character_name = event.pages[0].graphic
      super($game_map.map_id, event)
      self.action_attachment(action_id)
      self.tool_id = action_id
      self.diagonal = false
      self.diagonal_direction = 0
      self.sprite_angle_enable = false
      @action.user = user
      @remain_for_an_act = @action.duration.is_a?(Numeric)
      check_tool_effects(user,skill,pre_direction)
  end
  
  #--------------------------------------------------------------------------
  # ● update 
  #--------------------------------------------------------------------------
  def update
      super
      if @action == nil and @remain_for_an_act
         erase 
         $game_system.tools_on_map.delete(self.tool_id)
      end
      check_event_trigger_attack
  end
end

#===============================================================================
# ■ Game Player
#===============================================================================
class Game_Player < Game_Character
  attr_accessor :need_refresh
end

#===============================================================================
# ■ Token_Bullet  
#===============================================================================
class Token_Bullet < Token_Event
  
  #--------------------------------------------------------------------------
  # ● Check Tool Effects
  #-------------------------------------------------------------------------- 
  def check_tool_effects(user,skill,pre_direction)
      if @action.ally_damage or @action.all_damage or user.battler.state_suicide
         user.battler.invunerable_duration = 0
      end
     # Force Update Out Screen
     if user.battler.sensor_range >= 15 or
        skill.note =~ /<Update Out Screen>/
        self.force_update = true
     end  
     #Diagonal Effect
     if skill.note =~ /<Diagonal>/ or
        skill.note =~ /<All Direction>/ or
        skill.note =~ /<Three Direction>/
        self.diagonal = true
        self.diagonal_direction = user.diagonal_direction
        self.sprite_angle_enable = true
        user.diagonal_time = XAS_BA::DIAGONAL_DURATION if user.diagonal_direction != 0
        user.diagonal = true if user.tool_id > 0        
     end 
     #Auto Target 
     if skill.note =~ /<Auto Target>/
        if user.is_a?(Game_Event)
           self.moveto($game_player.x, $game_player.y)
        else  
           moveto($game_temp.xas_target_x, $game_temp.xas_target_y)
           $game_temp.xas_target_x = 0
           $game_temp.xas_target_y = 0      
           $game_temp.xas_target_time = 0
           $game_temp.xas_target_shoot_id = 0
        end   
     end
     #Barrier 
     if skill.note =~ /<Barrier>/
        self.tool_effect = "Barrier"
     end
     #Boomerang
     if skill.note =~ /<Boomerang = (\d+)>/
        self.tool_effect = "Boomerang"
        self.action.duration = 1000
        self.diagonal = true
        self.diagonal_direction = user.diagonal_direction
        self.force_update = true
        @move_frequency = 6
        @move_speed = 5
        @direction_fix = false
        @walk_anime = true
        @step_anime = true
        @force_action = "Forward" 
        @force_action_times = $1.to_i
     #Guide  
     elsif skill.note =~ /<Guide>/
        self.tool_effect = "Guide"
        self.diagonal = true
        self.diagonal_direction = user.diagonal_direction
        self.force_update = true
        @move_frequency = 6
        @move_speed = 5
        @force_action = "Guide"
        @force_action_times = 30
        @self_target = 0
        near_check = -1
        for event in $game_map.events.values
          next unless event.battler.is_a?(Game_Enemy) 
          next if event.battler.dead?
          next if event.erased
          next if event.battler.invunerable
          next if event.battler.no_damage_pop
          cx = ( event.x - user.x ).abs
          cy = ( event.y - user.y ).abs
          if ( cx * cy ) == 0
            if near_check > cx + cy || near_check < 0
              near_check = ( cx + cy )
              @self_target = event.id
            end
          else
            if near_check > Math.sqrt( ( cx * cx ) + ( cy * cy ) ) || near_check < 0
              near_check = Math.sqrt( ( cx * cx ) + ( cy * cy ) ) 
              @self_target = event.id
            end
          end
          @self_target = -1 if user.battler.is_a?(Game_Enemy)
        end
     end     
      
   end
 
end 



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ TOOL - AREA
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ XAS ACTION
#===============================================================================
module XAS_ACTION

  #--------------------------------------------------------------------------
  # ● action_update
  #--------------------------------------------------------------------------
  def action_update
      return unless @action.is_a?(Game_Action_XAS)
      if @action.animation_time != [] and
         @action.animation_time[0] == @action.now_count
         animation_id = @action.animation_time[1]
         unless self.is_a?(Game_Player) or self.tool_id == 0
             self.animation_id = animation_id 
         end
      end
      @action.update
  end
    
  #--------------------------------------------------------------------------
  # ● Can Impact Target
  #--------------------------------------------------------------------------  
  def can_impact_target?
      return false if @action.nil? 
      return false if @action.attack_id == 0 
      return false if @action.first_impact_time > 0
      return false if @action.impact == false
      return false if self.jumping?
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● check_event_trigger_attack
  #--------------------------------------------------------------------------
  def check_event_trigger_attack()
      return unless can_impact_target?
      hit_check = false
      range = @action.attack_range
      hit = []
      targets = [$game_player] + $game_map.events.values
      for event in targets
        next if event == self or
                @action.hit_events.include?(event) or event.erased
        body_size      = event.body_size
        event_center_x = event.x 
        event_center_y = event.y - body_size
        if @action.short_range
           dx = event_center_x - $game_player.x
           dy = event_center_y - $game_player.y
        else
           dx = event_center_x - self.x
           dy = event_center_y - self.y
         end
        dx = (dx >= 0 ? [dx - body_size, 0].max : [dx + body_size, 0].min)
        dy = (dy >= 0 ? [dy - body_size, 0].max : [dy + body_size, 0].min)
        hit_check = true if in_range?(dx,dy,event,range) 
        hit.push(event) if hit_check
        hit_check = false
      end
      for event in hit
          if event.action_effect(self, self.action.attack_id)
             hit_check = true
          end
          if event.action_effect_page(self, self.action.attack_id)
             hit_check = true
         end         
         @action.hit_events.push(event) unless @action.multi_hit
         end
      if hit_check
         $game_temp.active_token = self
      end
  end

  #--------------------------------------------------------------------------
  # ● In Range?
  #--------------------------------------------------------------------------  
  def in_range?(dx,dy,event,range) 
      case @action.attack_range_type
            when 1 #RHOMBUS
              return true if (dx.abs + dy.abs <= range)
            when 2 #SQUARE
              return true if (dx.abs <= range and dy.abs <= range)
            when 3 #LINE
              case self.direction
                  when 2
                    return true if (dx == 0 and dy >= 0 and dy <= range)
                  when 8
                    return true if (dx == 0 and dy <= 0 and dy >= -range)
                  when 6
                    return true if (dy == 0 and dx >= 0 and dx <= range)
                  when 4
                    return true if (dy == 0 and dx <= 0 and dx >= -range)
              end
            when 4  #FRONT SQUARE   
              case self.direction
                 when 2
                    return true if (dx.abs <= range and dy >= 0 and dy.abs <= range)
                 when 4
                    return true if (dx.abs <= range and dx <= 0 and dy.abs <= range)  
                 when 6
                    return true if (dx.abs <= range and dx >= 0 and dy.abs <= range)
                 when 8
                    return true if (dx.abs <= range and dy <= 0 and dy.abs <= range)
              end              
            when 5  #FRONT RHOMBUS     
              case self.direction
                  when 2
                    return true if (dx.abs + dy.abs <= range and dy >= 0)
                  when 8
                    return true if (dx.abs + dy.abs <= range and dy <= 0)
                  when 6
                    return true if (dx.abs + dy.abs <= range and dx >= 0)
                  when 4
                    return true if (dx.abs + dy.abs <= range and dx <= 0)
              end          
            when 6  #WALL
              case self.direction
                 when 2
                    return true if (dx.abs <= range and dy == 0 )
                 when 4
                    return true if (dy.abs <= range and dx == 0)  
                 when 6
                    return true if (dy.abs <= range and dx == 0)
                 when 8
                    return true if (dx.abs <= range and dy == 0)
               end  
            when 7 #CROSS
                 return true if (dx.abs <= range and dy == 0)
                 return true if (dy.abs <= range and dx == 0)  
            end
     return false       
  end      
  
  #--------------------------------------------------------------------------
  # ●  action_effect Page
  #--------------------------------------------------------------------------
  def action_effect_page(attacker, attack_id)
      return false unless self.is_a?(Game_Event)
      return false if attacker.action.fake_id
      if attacker.action != nil
         check_auto_effect_page(attacker, attack_id) 
         check_reflectable_skills(attacker, attack_id)
      end
      for page in @event.pages
          if page.condition.variable_valid and
             page.condition.variable_id == XAS_SYSTEM::HIT_ID and 
             page.condition.variable_value == attack_id
             self.reaction_valid_attack_id = attack_id
             self.refresh
             @trigger = 0
             self.start
             return true
          end
      end
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Check Reflectable Skills
  #--------------------------------------------------------------------------    
  def check_reflectable_skills(attacker, attack_id)
      return if self.tool_id == 0
      return unless self.action.reflectable
      return unless attacker.action.can_reflect
      self.action.user = attacker.action.user
      self.action.hit_events = []  
      self.turn_back
  end  
  
  #--------------------------------------------------------------------------
  # ● Check Auto Effect Page
  #--------------------------------------------------------------------------  
  def check_auto_effect_page(attacker, attack_id)
      if self.treasure_time > 0
         if can_hit_take_treasure?(attacker, attack_id)
            execute_take_treasure(attacker, attack_id) 
         elsif self.temp_id == 0 and can_hold_treasure?(attacker, attack_id)   
            execute_hold_treasure(attacker, attack_id) 
         end  
      end
  end
  
  #--------------------------------------------------------------------------
  # ● Can Hit Take Treasure
  #--------------------------------------------------------------------------      
  def can_hit_take_treasure?(attacker, attack_id)
      return true if attacker.action.short_range
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Can Hold Treasure?
  #--------------------------------------------------------------------------        
  def can_hold_treasure?(attacker, attack_id)
      return true if attacker.tool_effect == "Boomerang"   
      return false 
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute Hold Treasure
  #--------------------------------------------------------------------------      
  def execute_hold_treasure(attacker, attack_id)
      tr_time = (100 + XAS_BA::TREASURE_ERASE_TIME * 60) - 20
      return if self.treasure_time > tr_time
      self.temp_id = attacker.id    
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute Take Treasure
  #--------------------------------------------------------------------------      
  def execute_take_treasure(attacker, attack_id)
      tr_time = (100 + XAS_BA::TREASURE_ERASE_TIME * 60) - 20
      tr_time = 9999999999999999999
      return if self.treasure_time > tr_time
      self.x = $game_player.x
      self.y = $game_player.y
  end

  #--------------------------------------------------------------------------
  # ● body_size
  #--------------------------------------------------------------------------
  def body_size
      return 0
  end
  
  #--------------------------------------------------------------------------
  # ● action_clear
  #--------------------------------------------------------------------------
  def action_clear
      @action = nil
      @step_anime = false
  end
end

#===============================================================================
# ■ Game_Character
#===============================================================================
class Game_Character < Game_CharacterBase
    include XAS_ACTION
end

#===============================================================================
# ■  Game_Event
#===============================================================================
class Game_Event < Game_Character

  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  alias x_conditions_met conditions_met? 
  def conditions_met?(page)
      c = page.condition
      if c.variable_valid
         if c.variable_id == XAS_SYSTEM::HIT_ID and 
            c.variable_value == self.reaction_valid_attack_id
            return true
         end
       end
      x_conditions_met(page)
  end
  
end  

#===============================================================================
# ■  XAS_Dispose
#===============================================================================
module XAS_Dispose
  
  #--------------------------------------------------------------------------
  # ● update
  #--------------------------------------------------------------------------  
  def update
      action_update
      super
      if @action.is_a?(Game_Action_XAS) and @action.done?
         self.action_clear
      end
  end
end

#===============================================================================
# ■  Game_Player
#===============================================================================
class Game_Player < Game_Character
  include XAS_Dispose
end

#===============================================================================
# ■  Game_Event
#===============================================================================
class Game_Event < Game_Character
  include XAS_Dispose
end

#===============================================================================
# ■ XAS_StopToAction 
#===============================================================================
module XAS_StopToAction
  
  #--------------------------------------------------------------------------
  # ● acting? 
  #--------------------------------------------------------------------------  
  def acting?
      return false if self.battler == nil
      return true if self.battler.shield
      return true if self.action != nil 
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● moving? 
  #--------------------------------------------------------------------------  
  def moving?
      return (super or self.acting? or self.stop)
  end
    
end

#===============================================================================
# ■ Game_Player  
#===============================================================================
class Game_Player < Game_Character
  include XAS_StopToAction
end

#===============================================================================
# ■ Game_Event  
#===============================================================================
class Game_Event < Game_Character
  attr_accessor :reaction_valid_attack_id
end


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ TOOL - HIT EFFECT
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ XRXS_BattlerAttachment
#==============================================================================
module XRXS_BattlerAttachment 

  #--------------------------------------------------------------------------
  # ● Can Hit Base?
  #--------------------------------------------------------------------------    
  def can_hit_base?(bullet, action_id)
      return false unless $game_system.xas_battle
      return false if self.battler == nil 
      return false if bullet == nil
      return false if action_id == nil or action_id <= 0
      return false if self.can_update == false
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● Action Effect
  #--------------------------------------------------------------------------  
  def action_effect(bullet, action_id)
      return unless can_hit_base?(bullet, action_id)
      skill = $data_skills[action_id]
      user = bullet.action.user
      attacker = (user == nil ? nil : user.battler)     
      tar_invu = bullet.action.target_invunerable_duration
      #CAN HIT?
      return unless action_can_hit_target?(bullet, user, skill,tar_invu)
      #REFLECT STATE
      return if reflect_state?(bullet, skill)
      #SHIELD 
      if target_shield_enabled?(attacker, skill, bullet)
         execute_guard_effect(user, skill, bullet, tar_invu)
         return 
      end
      #INVUNERABLE ACTIONS
      if target_invunerable_actions?(user, skill, bullet)
         execute_guard_effect(user, skill, bullet, tar_invu, false)
         return
      end   
      #GUARD DIRECTIONS
      if target_guard_directions?(user, skill, bullet)
         execute_guard_effect(user, skill, bullet, tar_invu)
         return        
      end  
      execute_hit_effect(attacker,skill, bullet , user, tar_invu )
      if self.is_a?(Game_Player)
         self.need_refresh = true
      end
  end

  #--------------------------------------------------------------------------
  # ● Reflect State?
  #--------------------------------------------------------------------------                 
  def reflect_state?(bullet, skill)
      if  bullet.action.reflectable and self.battler.state_reflect
          if skill.note =~ /<Auto Target>/
             bullet.moveto(bullet.action.user.x,bullet.action.user.y)
          else   
             bullet.turn_back
          end  
          bullet.action.user = self
          bullet.action.hit_events = []           
          bullet.turn_back
#          bullet.jump(0,0)
          bullet.turn_back
          self.battler.damage = XAS_WORD::REFLECT
          self.battler.damage_pop = true
          self.animation_id = XAS_ANIMATION::REFLECT_ANIMATION_ID
#~           self.battler.invunerable_duration = 20
         return true
     end 
     return false     
  end
  
 #--------------------------------------------------------------------------
 # ● Target Guard Directions?
 #--------------------------------------------------------------------------    
 def target_guard_directions?(user, skill, bullet)
     return false if self.battler.guard == false
     return false if bullet.action.ignore_guard
     if self.battler.guard_directions.include?(2) and
        ((self.direction == 2 and bullet.direction == 8) or
         (self.direction == 8 and bullet.direction == 2) or
         (self.direction == 6 and bullet.direction == 4) or
         (self.direction == 4 and bullet.direction == 6))
         return true
     elsif self.battler.guard_directions.include?(8) and
        ((self.direction == 8 and bullet.direction == 8) or
         (self.direction == 2 and bullet.direction == 2) or
         (self.direction == 6 and bullet.direction == 6) or
         (self.direction == 4 and bullet.direction == 4))
         return true
     elsif self.battler.guard_directions.include?(4) and
        ((self.direction == 2 and bullet.direction == 4) or
         (self.direction == 8 and bullet.direction == 6) or
         (self.direction == 6 and bullet.direction == 2) or
         (self.direction == 4 and bullet.direction == 8))
         return true         
     elsif self.battler.guard_directions.include?(6) and
        ((self.direction == 2 and bullet.direction == 6) or
         (self.direction == 8 and bullet.direction == 4) or
         (self.direction == 6 and bullet.direction == 8) or
         (self.direction == 4 and bullet.direction == 2))
         return true
     end       
     return false
  end
      
  #--------------------------------------------------------------------------
  # ● Target Invunerable Actions?
  #--------------------------------------------------------------------------            
  def target_invunerable_actions?(user, skill, bullet)
      return true if self.battler.invunerable_actions.include?(skill.id)
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Shoot Target Shield
  #--------------------------------------------------------------------------          
  def shoot_target_shield?(bullet,user, skill)
      return false unless self.battler.shield
      return false if bullet.action.ignore_guard
      return true if face_direction?(bullet)
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Action can hit target?
  #--------------------------------------------------------------------------        
  def action_can_hit_target?(bullet, user, skill,tar_invu)
      if user == nil
         return false
      end   
      if self.battler.invunerable
         return false
      end  
      if self.battler.dead?
         return false
      end   
      if self.battler.no_damage_pop and self.battler.hp == 0
         return false
      end   
      if self.battler.invunerable_duration > 0
         return false
      end   
      if @knock_back_duration != nil 
         return false unless bullet.action.ignore_knockback_invincible
      end
      if bullet.action.first_impact_time > 0
         return false 
      end
      if self.action != nil and self.action.user_invincible
         unless self.action.ally_damage and bullet.action.user == self.action.user and user.battler.state_suicide
             return false
         end
      end  
      unless bullet.action.all_damage 
             if bullet.action.ally_damage or user.battler.state_suicide
                if user.battler.is_a?(Game_Actor)
                   return false if self.battler.is_a?(Game_Enemy)
                elsif user.battler.is_a?(Game_Enemy) 
                   return false if self.battler.is_a?(Game_Actor)
                end
             else    
                if user.battler.is_a?(Game_Actor)
                   return false if self.battler.is_a?(Game_Actor)
                elsif user.battler.is_a?(Game_Enemy) 
                   return false if self.battler.is_a?(Game_Enemy)
                end                 
             end              
      end
      return false if target_state_invunerable?(tar_invu)
      #return false if target_reflect_action?(bullet, user)
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● Target Relfect Action
  #--------------------------------------------------------------------------          
  def target_reflect_action?(bullet, user)
      return false unless bullet.action.reflectable
      for i in $game_map.events.values
          if i.tool_id > 0 and i.action.can_reflect and
             i.tool_effect == "Barrier"# and i.action.user.battler.is_a?(self.battler)
             bullet.action.user = self
             bullet.action.hit_events = []  
             bullet.turn_back
             return true
             break
          end   
      end
      return false  
  end
  
  #--------------------------------------------------------------------------
  # ● Target State Invunerable
  #--------------------------------------------------------------------------        
  def target_state_invunerable?(tar_invu)
      if self.battler.state_invunerable
         self.battler.damage = XAS_WORD::INVINCIBLE 
         self.battler.damage_pop = true
         self.animation_id = XAS_ANIMATION::INVINCIBLE_ANIMATION_ID
         self.battler.invunerable_duration = tar_invu
         return true
      end
      return false
  end
  
  #--------------------------------------------------------------------------
  # ● Execute Hit Effect
  #--------------------------------------------------------------------------      
  def execute_hit_effect(attacker,skill, bullet , user, tar_invu)
      shoot_effect_before_damage(skill, bullet, user)
      execute_battler_skill_effect(attacker ,skill, user)        
      if target_missed?(attacker)
#~          p bullet.tool_effect == "Guide"
         bullet.action.duration = 1 if bullet.tool_effect == "Guide"
#~          self.battler.invunerable_duration = 0 #self.battler.knockback_duration
         return 
      end            
      execute_damage_pop(attacker,skill)
      shoot_effect_after_damage(skill, bullet, user) if can_damage_after_effect?
      execute_state_effect(skill, user,  bullet)    
      bullet.action.duration = 1 if remove_tool_after_hit?(skill, bullet, user)
      self.battler.invunerable_duration = tar_invu
      execute_blow_effect(skill,bullet) if can_blow_effect?
      execute_animation(skill, bullet, user)
      execute_tool_effects(skill, bullet , user)
  end
 
  #--------------------------------------------------------------------------
  # ● Execute Tool Effects
  #--------------------------------------------------------------------------              
  def execute_tool_effects(skill, bullet , user)
      execute_sticky_effect(skill, bullet, user)
      execute_bounce_effect(skill, bullet, user)
      execute_hit_action_effect(skill, bullet, user)
  end
    
  #--------------------------------------------------------------------------
  # ● Remove Tool After Hit?
  #--------------------------------------------------------------------------            
  def remove_tool_after_hit?(skill, bullet, user)
      return true if bullet.action.piercing == false
      return false
  end  
 
  #--------------------------------------------------------------------------
  # ● Execute Battler Skill Effect
  #--------------------------------------------------------------------------          
  def execute_battler_skill_effect(attacker ,skill, user)
      self.battler.item_apply(attacker, skill)
  end
  
  #--------------------------------------------------------------------------
  # ● Target Missed?
  #--------------------------------------------------------------------------        
  def target_missed?(attacker)
      if self.battler.result.missed 
         self.battler.damage = XAS_WORD::MISSED
         self.battler.damage_pop = true         
         return true
      end    
      if self.battler.result.evaded
         self.battler.damage = XAS_WORD::EVADED
         self.battler.damage_pop = true             
         return true 
      end  
      return false
  end  
  #--------------------------------------------------------------------------
  # ● Shoot Effect Before Damage
  #--------------------------------------------------------------------------        
  def shoot_effect_before_damage(skill, bullet, user)
  end
  
  #--------------------------------------------------------------------------
  # ● Shoot Effect After Damage
  #--------------------------------------------------------------------------          
  def shoot_effect_after_damage(skill, bullet, user)
      check_counter_attack(skill)
      self.battler.passive = false
  end
  
  #--------------------------------------------------------------------------
  # ● Shoot Effect After Damage
  #--------------------------------------------------------------------------            
  def check_counter_attack(skill)
      return if self.battler.is_a?(Game_Actor)
      return if self.battler.counter_action[2] == false
      return if self.battler.counter_action[1] > 0
      counter = XAS_BA_ENEMY::COUNTER_ATTACK[self.battler.enemy_id]
      if counter != nil
         counter_action_id = counter[rand(counter.size)]
         self.battler.counter_action[0] = counter_action_id
         self.battler.counter_action[1] = 15
      end  
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute Bounce Effect
  #--------------------------------------------------------------------------             
  def execute_bounce_effect(skill, bullet, user)
      return false if bullet.action.hit_bounce == false
      bullet.bounce_direction
  end
  
  #--------------------------------------------------------------------------
  # ● Execute Stick Effect
  #--------------------------------------------------------------------------           
  def execute_sticky_effect(skill, bullet, user)
      return unless bullet.action.sticky
      return if bullet.temp_id !=  0
      bullet.pre_move_speed = bullet.move_speed
      bullet.temp_id = self.id
  end
  
  #--------------------------------------------------------------------------
  # ● Execute Hit Action Effect
  #--------------------------------------------------------------------------             
  def execute_hit_action_effect(skill, bullet, user)
      return if bullet.action.hit_action == 0
      self.battler.invunerable_duration = 1
      bullet.shoot(bullet.action.hit_action)
      bullet.action.duration = 9
      bullet.action.multi_hit = false
      bullet.character_name = ""
      bullet.x_pose_duration = 0
      bullet.x_pose_name = ""
      bullet.x_pose_original_name = ""       
  end
  
  #--------------------------------------------------------------------------
  # ● Can Damage Effect
  #--------------------------------------------------------------------------          
  def can_damage_after_effect?
      return false if self.battler.damage == nil
      return false unless self.battler.damage.is_a?(Numeric)
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute State Effect
  #--------------------------------------------------------------------------        
  def execute_state_effect(skill, user,  bullet)   
      if user.battler.states.size != 0
         for i in user.battler.states
             execute_state_effect_user(skill, user, bullet,i)
         end    
      end
      if self.battler.states.size != 0
         for i in self.battler.states
             execute_state_effect_target(skill, user, bullet,i)
         end    
      end
  end
  
  #--------------------------------------------------------------------------
  # ● Execute State Effect User
  #--------------------------------------------------------------------------          
  def execute_state_effect_user(skill, user, bullet,i)
  
  end
  
  #--------------------------------------------------------------------------
  # ● Execute State Target
  #--------------------------------------------------------------------------          
  def execute_state_effect_target(skill, user, bullet,i)
      #Sleep 
      if self.battler.damage.is_a?(Numeric) and self.battler.damage > 0
         if i.note =~ /<Sleep>/  
            self.battler.remove_state(i.id)
         end
      end   
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute Blow Effect
  #--------------------------------------------------------------------------      
  def execute_blow_effect(skill,bullet)
      if bullet.action.hit_hold_target and self.temp_id == 0     
         self.temp_id = bullet.id
         self.pre_move_speed = self.move_speed         
         self.moveto(bullet.x, bullet.y)
      end   
      $game_map.screen.start_shake(5, 5, 60) if bullet.action.hit_shake
      p = bullet.action.blow_power.to_i  
      d = bullet.direction    
      return if self.battler.damage.to_i <= 0
      return if p < 0
      self.blow(d, p)  
  end
    
  #--------------------------------------------------------------------------
  # ● Execute Animation
  #--------------------------------------------------------------------------        
  def execute_animation(skill, bullet, user)    
      self.animation_id = skill.animation_id
      tool_animation = bullet.action.second_animation_id
      user_animation = bullet.action.third_animation_id
      bullet.animation_id = tool_animation if tool_animation != 0
      user.animation_id = user_animation if user_animation != 0
  end  
    
  #--------------------------------------------------------------------------
  # ● Knock Back Disable
  #--------------------------------------------------------------------------      
  def knock_back_disable
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● Dead?
  #--------------------------------------------------------------------------          
  def dead?
    return self.battler == nil ? false : self.battler.dead?
  end
  
end


#===============================================================================
# ■ XRXS_BattlerAttachment
#==============================================================================
module XRXS_BattlerAttachment 
 
  #--------------------------------------------------------------------------
  # ● Shoot Target Shield
  #--------------------------------------------------------------------------          
  def target_shield_enabled?(attacker, skill, bullet)
      return false unless self.battler.shield
      if bullet != nil
         return false if bullet.action.ignore_guard
         return true if face_direction?(bullet)         
      else   
         return false if attacker.battler.ignore_guard
         return true if face_direction?(attacker)         
      end  
      return false
  end  

  #--------------------------------------------------------------------------
  # ● Can Blow Effect
  #--------------------------------------------------------------------------        
  def can_blow_effect?
      return false if self.battler.no_knockback
      return false if $game_map.interpreter.running?
      return true 
  end  
 
 #--------------------------------------------------------------------------
 # ● Execute Guard Effect
 #--------------------------------------------------------------------------      
 def execute_guard_effect(attacker, skill, bullet, inv, erase_bullet = true)
     self.battler.invunerable_duration = inv
     damage_pop(XAS_WORD::GUARD)
     guard_animation_id = XAS_ANIMATION::GUARD_ANIMATION_ID
     self.animation_id = guard_animation_id if guard_animation_id != 0   
     if bullet != nil 
        bullet.erase if erase_bullet
     else   
        blow_reverse(attacker) unless attacker.battler.no_knockback 
     end   
 end
   
 #--------------------------------------------------------------------------
 # ● Blow Reverse
 #--------------------------------------------------------------------------      
 def blow_reverse(attacker)
     return if attacker.battler.no_knockback
     case attacker.direction
        when 2
           d = 8
        when 4
           d = 6
        when 6
           d = 4 
        when 8  
           d = 2
     end
     attacker.jump(0,0)   
     attacker.blow(d,1)
 end 
 
 #--------------------------------------------------------------------------
 # ● Can Attack Effect
 #--------------------------------------------------------------------------      
 def damage_pop(text)
     return unless XAS_WORD::ENABLE_WORD
     self.battler.damage = text
     self.battler.damage_pop = true
 end
 
 #--------------------------------------------------------------------------
 # ● Shd Direction?
 #--------------------------------------------------------------------------      
 def face_direction?(attacker)
     target = self.direction  
     case target
          when 2
             return true if attacker.direction == 8
          when 4
             return true if attacker.direction == 6
          when 6
             return true if attacker.direction == 4
          when 8  
             return true if attacker.direction == 2     
     end
     return false
 end   
 
 #--------------------------------------------------------------------------
 # ● Execute Damage Pop
 #--------------------------------------------------------------------------       
 def execute_damage_pop(attacker,skill = nil)
     if skill != nil
        return if skill.note =~ /<No Damage Pop>/
        if skill.damage.to_mp?
           dam = self.battler.result.mp_damage
           self.battler.damage_type = "Mp"      
        elsif skill.damage.to_hp?
           dam = self.battler.result.hp_damage 
           self.battler.damage_type = "Critical"  if self.battler.result.critical 
        end   
        if dam != nil 
           if skill.damage.drain? or skill.damage.drain?
              attacker.damage = -dam
              attacker.damage_type = self.battler.damage_type 
              attacker.damage_pop = true
           end  
           self.battler.damage = dam
           self.battler.damage_pop = true
        end
     else
        if self.battler.result.hp_damage != nil
           self.battler.damage = self.battler.result.hp_damage 
           self.battler.damage_type = "Critical" if self.battler.result.critical   
           self.battler.damage_pop = true      
        end   
     end  
 end  
 
 #--------------------------------------------------------------------------
 # ● Execute Damage Pop
 #--------------------------------------------------------------------------       
 def execute_suicide_damage_pop(attacker,skill = nil)
     if skill != nil
        return if skill.note =~ /<No Damage Pop>/
        if skill.damage.to_mp?
           dam = attacker.battler.result.mp_damage
           attacker.battler.damage_type = "Mp"      
        elsif skill.damage.to_hp?
           dam = attacker.battler.result.hp_damage 
           attacker.battler.damage_type = "Critical"  if attacker.battler.result.critical 
        end   
        if dam != nil 
           if skill.damage.drain? or skill.damage.drain?
              attacker.damage = -dam
              attacker.damage_type = attacker.battler.damage_type 
              attacker.damage_pop = true
           end  
           attacker.battler.damage = dam
           attacker.battler.damage_pop = true
        end
     else
        if attacker.battler.result.hp_damage != nil
           attacker.battler.damage = attacker.battler.result.hp_damage 
           attacker.battler.damage_type = "Critical" if attacker.battler.result.critical   
           attacker.battler.damage_pop = true      
        end   
     end  
 end  
 
end   



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ TOOL - EQUIP
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#~ #==============================================================================
#~ # ■ Window Skill List
#~ #==============================================================================
#~ class Window_SkillList < Window_Selectable
#~   
#~   #--------------------------------------------------------------------------
#~   # ● Process OK
#~   #--------------------------------------------------------------------------                   
#~   alias x_skill_process_ok process_ok
#~   def process_ok
#~       return if can_equip_skill_action?
#~       x_skill_process_ok
#~   end

#~   #--------------------------------------------------------------------------
#~   # ● Can Equip Skill Action
#~   #--------------------------------------------------------------------------                     
#~   def can_equip_skill_action?
#~       return false if $game_party.in_battle 
#~       skill = @data[index]
#~       if skill != nil and skill.note =~ /<Duration = (\d+)>/
#~          @actor.skill_id = skill.id
#~          Sound.play_equip
#~          return true         
#~       end
#~       return false
#~   end
#~   
#~ end

#~ #==============================================================================
#~ # ■ Window Item List
#~ #==============================================================================
#~ class Window_ItemList < Window_Selectable
#~   
#~   #--------------------------------------------------------------------------
#~   # ● Process OK
#~   #--------------------------------------------------------------------------                   
#~   alias x_item_process_ok process_ok
#~   def process_ok
#~       return if can_equip_item_action?
#~       x_item_process_ok
#~   end

#~   #--------------------------------------------------------------------------
#~   # ● Can Equip Item Action
#~   #--------------------------------------------------------------------------                     
#~   def can_equip_item_action?
#~       return false if $game_party.in_battle 
#~       item = @data[index]
#~       if item != nil and item.is_a?(RPG::Item) and
#~          item.note =~ /<Action ID = (\d+)>/
#~          actor = $game_party.members[0]
#~          actor.item_id = item.id
#~          Sound.play_equip
#~          return true         
#~       end
#~       return false
#~   end
#~   
#~ end

#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - INITIALIZE
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game Character
#==============================================================================
class Game_Character < Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # ● Update Battler
  #--------------------------------------------------------------------------      
  def update_battler
      update_battler_pose 
      update_battler_parameters
      update_battler_stop_movement
      update_battler_knockbacking
      update_battler_counter_action
      @gain_duration = self.battler.gain_duration
      unless self.battler.hp == 0
          update_battler_cast_action    
          update_battler_move_speed if can_update_battler_move_speed?
          update_battler_states_effect
          update_battler_attacking
      else
          update_battler_defeat_process
      end 
  end  

end

#===============================================================================
# ■ Game Player
#===============================================================================
class Game_Player < Game_Character
  include XRXS_BattlerAttachment
  
  #--------------------------------------------------------------------------
  # ● Battler
  #--------------------------------------------------------------------------  
  def battler
      return $game_party.members[0]
  end
  
  #--------------------------------------------------------------------------
  # ● Refresh Interpreter Effect
  #--------------------------------------------------------------------------        
  def refresh_interpreter_effect 
      $game_system.old_interpreter_running = $game_map.interpreter.running?
      if $game_system.old_interpreter_running 
         $game_temp.reset_battler_time = 60 * 4
      end  
      reset_battler_setting  
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Battler Setting Time
  #--------------------------------------------------------------------------           
  def update_reset_battler_setting_time
      return if $game_temp.reset_battler_time == 0
      $game_temp.reset_battler_time -= 1
      reset_battler_setting_running if $game_temp.reset_battler_time == 0
  end
  
  #--------------------------------------------------------------------------
  # ● Update Battler Setting
  #--------------------------------------------------------------------------         
  def reset_battler_setting
      reset_player_parameters
      for ally in $game_party.members
         reset_members_parameters(ally)
      end
      for enemy in $game_map.events.values 
          reset_enemies_parameters(enemy) if enemy.battler != nil
      end    
      $game_map.need_refresh = true  
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Battler Setting Running
  #--------------------------------------------------------------------------         
  def reset_battler_setting_running
      reset_player_parameters_running
      for ally in $game_party.members
         reset_members_parameters_running(ally)
      end
      for enemy in $game_map.events.values 
          reset_enemies_parameters(enemy) if enemy.battler != nil
      end    
      $game_map.need_refresh = true  
  end    
  
  #--------------------------------------------------------------------------
  # ● Reset Enemies Parameters
  #--------------------------------------------------------------------------          
  def reset_enemies_parameters(enemy)
      enemy.battler.cast_action[0] = 0
      enemy.battler.cast_action[1] = 0
      enemy.battler.cast_action[2] = 0
      enemy.battler.cast_action[3] = 0  
      enemy.battler.cast_action[4] = 0
      enemy.battler.counter_action[0] = 0
      enemy.battler.counter_action[1] = 0
      enemy.battler.counter_action[2] = true
      enemy.battler.invunerable_duration = 0
      enemy.knock_back_duration = nil
  end  
  
  #--------------------------------------------------------------------------
  # ● Reset Members Parameters
  #--------------------------------------------------------------------------          
  def reset_members_parameters(ally)
      ally.old_level = ally.level
      ally.shield = false
      ally.x_charge_action[0] = 0
      ally.x_charge_action[1] = 0
      ally.x_charge_action[2] = 0
      ally.x_charge_action[3] = 0
      ally.cast_action[0] = 0
      ally.cast_action[1] = 0
      ally.cast_action[2] = 0
      ally.cast_action[3] = 0  
      ally.cast_action[4] = 0
      ally.counter_action[0] = 0
      ally.counter_action[1] = 0
      ally.counter_action[2] = true
      ally.invunerable_duration = 0
  end
  
  #--------------------------------------------------------------------------
  # ● Reset Player Parameters
  #--------------------------------------------------------------------------          
  def reset_player_parameters
      make_pose("", 1) unless $game_player.action != nil
      $game_temp.xas_target_time = 0
      $game_temp.xas_target_shoot_id = 0
      $game_temp.xas_target_x = 0       
      @knock_back_duration = nil
      @dash_active = false
  end
    
  
  #--------------------------------------------------------------------------
  # ● Reset Members Parameters Running
  #--------------------------------------------------------------------------          
  def reset_members_parameters_running(ally)
      ally.old_level = ally.level
      ally.shield = false
      unless ally.x_charge_action[1] > 0
      ally.x_charge_action[0] = 0
      ally.x_charge_action[1] = 0
      ally.x_charge_action[2] = 0
      ally.x_charge_action[3] = 0
      end
      unless ally.cast_action[1] > 0
         ally.cast_action[0] = 0
         ally.cast_action[1] = 0
         ally.cast_action[2] = 0
         ally.cast_action[3] = 0  
         ally.cast_action[4] = 0
      end
      ally.counter_action[0] = 0
      ally.counter_action[1] = 0
      ally.counter_action[2] = true
      ally.invunerable_duration = 0
  end
  
  #--------------------------------------------------------------------------
  # ● Reset Player Parameters Running
  #--------------------------------------------------------------------------          
  def reset_player_parameters_running
      $game_temp.xas_target_time = 0
      $game_temp.xas_target_shoot_id = 0
      $game_temp.xas_target_x = 0       
      @knock_back_duration = nil
      @dash_active = false
  end
  
end

#===============================================================================
# ■ Game Follower
#===============================================================================
class Game_Follower < Game_Character
  include XRXS_BattlerAttachment
  
  #--------------------------------------------------------------------------
  # ● Battler
  #--------------------------------------------------------------------------    
  def battler
      return $game_party.members[@member_index]
  end
end

#===============================================================================
# ■ Game Follower
#===============================================================================
class Game_Followers 
  include XRXS_BattlerAttachment
  
  #--------------------------------------------------------------------------
  # ● Battler
  #--------------------------------------------------------------------------    
  def battler
      return $game_party.members[@member_index]
  end
end
#===============================================================================
# ■ Game_Vehicle
#===============================================================================
class Game_Vehicle < Game_Character
  include XRXS_BattlerAttachment
  attr_reader   :collision_attack
  
  #--------------------------------------------------------------------------
  # ● Battler
  #--------------------------------------------------------------------------      
  def battler
     return @battler
  end  
end  

#===============================================================================
# ■ Game Event
#===============================================================================
class Game_Event < Game_Character
  
  include XRXS_BattlerAttachment
  
  #--------------------------------------------------------------------------
  # ● Battler
  #--------------------------------------------------------------------------    
  def battler
    return @battler
  end
  
 #--------------------------------------------------------------------------
 # ● Battler?
 #--------------------------------------------------------------------------           
 def battler?
     return false if self.erased
     return false if self.battler == nil
     return false if self.dead?
     return false if self.battler.no_damage_pop
     return false if self.battler.invunerable
     return true
 end  
 
  #--------------------------------------------------------------------------
  # ● Refresh
  #--------------------------------------------------------------------------    
  alias xrxs64c_refresh refresh
  def refresh
      xrxs64c_refresh
      self.battler_recheck
  end
    
  #--------------------------------------------------------------------------
  # ● Battler Recheck
  #--------------------------------------------------------------------------    
  def battler_recheck
      return if @battler != nil
      return if @page == nil
      if self.name =~ /<Actor>/       
         actor = $game_party.members[0]
         @battler = Game_Actor.new(actor.id)
         return
      else
         @enemy_id = 0
         if self.name =~ /<Enemy(\d+)>/i
            @enemy_id = $1.to_i
            $game_troop.events_respawn_time = [] if $game_troop.events_respawn_time == nil
            $game_troop.events_respawn_time.each { | i |
            self.erase if i[0] == @map_id && i[1] == self.id
            $game_troop.events_respawn_time.delete(i) if i[0] == @map_id && i[1] == self.id && i[2] == -1 && !self.name =~ /<UNSPAWN>/i
            }
         end
         return if @enemy_id <= 0
         @battler = Game_Enemy.new(1, @enemy_id)
         self.force_update = true if self.battler.sensor_range >= 15         
      end  
  end
  
  #--------------------------------------------------------------------------
  # ● Battler Recheck
  #--------------------------------------------------------------------------      
  def enemy_id
      return @enemy_id
  end
  
  #--------------------------------------------------------------------------
  # ● body_size
  #--------------------------------------------------------------------------        
  def body_size
      if self.battler != nil
         return self.battler.body_size
      else
         return 0
      end  
  end

end


#===============================================================================
# ■ Game_Battler
#===============================================================================
class Game_Battler 
  attr_accessor :sensor_range
  attr_accessor :body_size
  attr_accessor :breath_effect
  attr_accessor :breath_duration
  attr_accessor :fast_breath_effect
  attr_accessor :no_knockback
  attr_accessor :passive  
  attr_accessor :attack_animation_id
  attr_accessor :ignore_guard
  attr_accessor :no_damage_pop
  attr_accessor :hud_switch
  attr_accessor :hud_swi
  attr_accessor :gain_exp_act #new
  attr_accessor :no_damage #new
  attr_accessor :sensor_range_type #new
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------      
  alias x_e_initialize initialize 
  def initialize  
      x_e_initialize
      @sensor_range = 4
      @body_size = 0
      @breath_effect = false
      @breath_duration = 0
      @fast_breath_effect = false
      @no_knockback = false
      @passive = false     
      @attack_animation_id = 0
      @ignore_guard = false
      @no_damage_pop = false
      @hud_switch = false
      @hud_swi = false
      @gain_exp_act = true #new
      @no_damage = false #new
      @sensor_range_type = 1
  end  
end

#===============================================================================
# ■ Game_Enemy
#===============================================================================
class Game_Enemy < Game_Battler
    
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------      
  alias x_e2_initialize initialize 
  def initialize(index, enemy_id)
      x_e2_initialize(index, enemy_id)
      enemy = $data_enemies[@enemy_id]
      setup_enemy_note(enemy)
      self.gain_exp_act = true #new
  end  
  
  #--------------------------------------------------------------------------
  # ● Setup X Note Elements
  #--------------------------------------------------------------------------          
  def setup_enemy_note(enemy)
      if enemy.note =~ /<Sensor Range = (\d+)>/
         @sensor_range = $1.to_i
      end   
      if enemy.note =~ /<Body Size = (\d+)>/
         @body_size = $1.to_i
      end
      if enemy.note =~ /<Attack Animation = (\d+)>/
         @attack_animation_id = $1.to_i
      end  
      if enemy.note =~ /<Death Zoom = (\d+)>/
         @death_zoom_effect = $1.to_i
      end 
      if enemy.note =~ /<Knockback Duration = (\d+)>/
         @knockback_duration = $1.to_i
      end       
      if enemy.note =~ /<Collapse Duration = (\d+)>/
         @collapse_duration_t = $1.to_i
      end       
      if enemy.note =~ /<TP = (\d+)>/  
         self.tp = $1.to_i
      end   
      if enemy.note =~ /<Ignore Guard>/ 
         @ignore_shield = true
      end
      if enemy.note =~ /<Surely Knockback>/
         @surely_knockback = true
      end
      if enemy.note =~ /<Invunerable>/ 
         @invunerable = true
      end
      if enemy.note =~ /<Breath Effect>/  
         @breath_effect = true
      end
      if enemy.note =~ /<Knockback Disable>/        
         @no_knockback = true
      end
      if enemy.note =~ /<Passive>/  
         @passive = true
      end
      if enemy.note =~ /<No Damage Pop>/  
         @no_damage_pop = true
      end   
      if enemy.note =~ /<Hud Switch>/  
         @hud_switch = true unless @hud_swi
         @hud_swi = true
      end   
      if enemy.note =~ /<No Diagonal Move>/  
         @diagonal = false
      end   
      if enemy.note =~ /<Sensor Range Area = (\w+)>/
         case $1
            when "CROSS"   
               area = 7
            when "WALL" 
               area = 6        
            when "FRONTRHOMBUS"  
               area = 5
            when "FRONTSQUARE"
               area = 4
            when "LINE"
               area = 3
            when "SQUARE"
               area = 2               
            else   
               area = 1 
         end     
         @sensor_range_type = area
      end   
      if enemy.note =~ /<Always Attack = (\d+)>/
        @always_attack = true
        @always_attack_id = $1.to_i
      else
        @always_attack = false
      end
      invunerable_actions_ids = XAS_BA_ENEMY::INVUNERABLE_ACTIONS[@enemy_id]
      if invunerable_actions_ids != nil
         @invunerable_actions = invunerable_actions_ids
      end   
      guard_directions_ids = XAS_BA_ENEMY::GUARD_DIRECTIONS[@enemy_id]
      if guard_directions_ids != nil
         @guard_directions = guard_directions_ids
      end          
  end
  
  
end  


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - EVENT SENSOR
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ XRXS_Enemy_Sensor
#===============================================================================
module XRXS_EnemySensor
  
  #--------------------------------------------------------------------------
  # ● Update Sensor
  #--------------------------------------------------------------------------        
  def update_sensor
      if self.battler != nil and self.battler.sensor_range > 0  
         sensor_area = self.battler.sensor_range
      else  
         sensor_area = $game_variables[XAS_BA::DEFAULT_SENSOR_RANGE_VARIABLE_ID]
      end
      sensor_area = -1 if cancel_sensor?
      enable = false
#~       distance = ($game_player.x - self.x).abs + ($game_player.y - self.y).abs
#~       enable   = (distance <= sensor_area)
#~       enable = true if (($game_player.x - self.x).abs + ($game_player.y - self.y).abs <= sensor_area)
      if self.battler.is_a?(Game_Enemy)
      case self.battler.sensor_range_type
            when 1 #RHOMBUS
              enable = true if (($game_player.x - self.x).abs + ($game_player.y - self.y).abs <= sensor_area)
            when 2 #SQUARE
              enable = true if (($game_player.x - self.x).abs <= sensor_area and ($game_player.y - self.y).abs <= sensor_area)
            when 3 #LINE
              case self.direction
                  when 2
                    enable = true if (($game_player.x - self.x) == 0 and ($game_player.y - self.y) >= 0 and ($game_player.y - self.y) <= sensor_area)
                  when 8
                    enable = true if (($game_player.x - self.x) == 0 and ($game_player.y - self.y) <= 0 and ($game_player.y - self.y) >= -sensor_area)
                  when 6
                    enable = true if (($game_player.y - self.y) == 0 and ($game_player.x - self.x) >= 0 and ($game_player.x - self.x) <= sensor_area)
                  when 4
                    enable = true if (($game_player.y - self.y) == 0 and ($game_player.x - self.x) <= 0 and ($game_player.x - self.x) >= -sensor_area)
              end
            when 4  #FRONT SQUARE   
              case self.direction
                 when 2
                    enable = true if (($game_player.x - self.x).abs <= range and ($game_player.y - self.y) >= 0 and ($game_player.y - self.y).abs <= sensor_area)
                 when 4
                    enable = true if (($game_player.x - self.x).abs <= range and ($game_player.x - self.x) <= 0 and ($game_player.y - self.y).abs <= sensor_area)  
                 when 6
                    enable = true if (($game_player.x - self.x).abs <= range and ($game_player.x - self.x) >= 0 and ($game_player.y - self.y).abs <= sensor_area)
                 when 8
                    enable = true if (($game_player.x - self.x).abs <= range and ($game_player.y - self.y) <= 0 and ($game_player.y - self.y).abs <= sensor_area)
              end              
            when 5  #FRONT RHOMBUS     
              case self.direction
                  when 2
                    enable = true if (($game_player.x - self.x).abs + ($game_player.y - self.y).abs <= sensor_area and ($game_player.y - self.y) >= 0)
                  when 8
                    enable = true if (($game_player.x - self.x).abs + ($game_player.y - self.y).abs <= sensor_area and ($game_player.y - self.y) <= 0)
                  when 6
                    enable = true if (($game_player.x - self.x).abs + ($game_player.y - self.y).abs <= sensor_area and ($game_player.x - self.x) >= 0)
                  when 4
                    enable = true if (($game_player.x - self.x).abs + ($game_player.y - self.y).abs <= sensor_area and ($game_player.x - self.x) <= 0)
              end          
            when 6  #WALL
              case self.direction
                 when 2
                    enable = true if (($game_player.x - self.x).abs <= sensor_area and ($game_player.y - self.y) == 0 )
                 when 4
                    enable = true if (($game_player.y - self.y).abs <= sensor_area and ($game_player.x - self.x) == 0)  
                 when 6
                    enable = true if (($game_player.y - self.y).abs <= sensor_area and ($game_player.x - self.x) == 0)
                 when 8
                    enable = true if (($game_player.x - self.x).abs <= sensor_area and ($game_player.y - self.y) == 0)
               end  
            when 7 #CROSS
                 enable = true if (($game_player.x - self.x).abs <= sensor_area and ($game_player.y - self.y) == 0)
                 enable = true if (($game_player.y - self.y).abs <= sensor_area and ($game_player.x - self.x) == 0)  
            end
      key = [$game_map.map_id, self.id, XAS_BA::SENSOR_SELF_SWITCH]
      last_enable = $game_self_switches[key]
      last_enable = false if last_enable == nil
      if enable != last_enable
         touch_attack(false)
         @collision_attack = false
         @pattern = 0
         @pattern_count = 0               
         $game_self_switches[key] = enable
         self.refresh
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● Can Update Sensor
  #--------------------------------------------------------------------------            
  def can_update_sensor?
      return false if @sensor_enable == false
      return false if self.dead? 
      return false if self.erased 
      return false if self.stop
      return false if self.knockbacking?
      return false if @event.name =~ /<Sensor(\d+)>/
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● refresh_sensor
  #--------------------------------------------------------------------------          
  def refresh_sensor
      touch_attack(false)
      key = [$game_map.map_id, self.id, XAS_BA::SENSOR_SELF_SWITCH]
      $game_self_switches[key] = false
      @pattern = 0
      @pattern_count  = 0         
      self.refresh        
  end  
  
  #--------------------------------------------------------------------------
  # ● Cancel Sensor
  #--------------------------------------------------------------------------          
  def cancel_sensor?  
      return false if self.battler == nil
      return true if self.battler.passive 
     if self.battler.sensor_range < 15
        return true if self.battler.state_invisible
        return true if $game_player.battler.state_invisible
     end
      return false
  end
  
end

#===============================================================================
# ■  Game Event
#===============================================================================
class Game_Event < Game_Character
  
  attr_accessor :sensor_enable
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------            
  alias x_sensor_initialize initialize
  def initialize(map_id, event)
      @sensor_enable = false
      x_sensor_initialize(map_id, event)
  end  
  
  #--------------------------------------------------------------------------
  # ● Conditions Met
  #--------------------------------------------------------------------------
  alias x_sensor_conditions_met conditions_met?
  def conditions_met?(page)
      c = page.condition
      if c.self_switch_ch == XAS_BA::SENSOR_SELF_SWITCH
         @sensor_enable = true
      end
      x_sensor_conditions_met(page)    
  end
end

#===============================================================================
# ■  Game Event
#===============================================================================
class Game_Character < Game_CharacterBase
      include XRXS_EnemySensor
end

#===============================================================================
# ■  Game Character
#===============================================================================
class Game_Character < Game_CharacterBase
      attr_writer   :opacity
end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - ACTION
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game Character
#==============================================================================
class Game_Character < Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # ● Can Update Battler Move Speed
  #--------------------------------------------------------------------------                  
  def can_update_battler_move_speed?
      return false if @temp_id > 0
      return false if moving?    
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● Can Update Battler?
  #--------------------------------------------------------------------------                
  def can_update_battler?
      return false unless $game_system.xas_battle
      return false if self.battler == nil
      return false unless party_system?
      return true
  end  

  #--------------------------------------------------------------------------
  # ● Party System
  #--------------------------------------------------------------------------                  
  def party_system?
      return false if self.battler == nil
      if $xas_party_system == nil and self.battler.is_a?(Game_Actor)
         return false if self.battler.actor_id != $game_party.members[0].actor_id 
      end
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● Reset Battler Temp
  #--------------------------------------------------------------------------                  
  def reset_battler_temp
      reset_cast_temp   
      reset_charge_temp 
  end  
  
  #--------------------------------------------------------------------------
  # ● Reset Charge Temp
  #--------------------------------------------------------------------------                    
  def reset_charge_temp  
      return if self.battler == nil
      return if self.battler.is_a?(Game_Enemy)
      self.battler.x_charge_action[0] = 0
      self.battler.x_charge_action[1] = 0
      self.battler.x_charge_action[2] = 0
      self.battler.x_charge_action[3] = 0
  end
  
  #--------------------------------------------------------------------------
  # ● Reset Battler Temp
  #--------------------------------------------------------------------------                    
  def reset_cast_temp   
      return if self.battler == nil
      self.battler.cast_action[0] = 0
      self.battler.cast_action[1] = 0
      self.battler.cast_action[2] = 0
      self.battler.cast_action[3] = 0  
      self.battler.cast_action[4] = 0
  end
    
  #--------------------------------------------------------------------------
  # ● update_battler_parameters
  #--------------------------------------------------------------------------    
  def update_battler_parameters
      @stop_count = -1 if can_stop_battler? 
      self.battler.invunerable_duration -= 1 if self.battler.invunerable_duration > 0 
      unless @stop
         @knock_back_duration = 30 if @temp_id > 0
      end   
  end    
  
  #--------------------------------------------------------------------------
  # ● Can Stop Battler
  #--------------------------------------------------------------------------      
  def can_stop_battler? 
      return false if self.is_a?(Game_Player)
      return true if self.knockbacking?
      return true if self.dead?
      return true if self.stop 
      return false 
  end
  
  #--------------------------------------------------------------------------
  # ● Update Battler Counter Action
  #--------------------------------------------------------------------------                    
  def update_battler_counter_action
      return if self.battler.counter_action[1] == 0
      self.battler.counter_action[1] -= 1
      if self.battler.counter_action[1] == 0
         turn_toward_player
         self.battler.damage = XAS_WORD::COUNTER
         self.battler.damage_pop = true 
         self.shoot(self.battler.counter_action[0])
         self.battler.counter_action[0] = 0
      end   
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Cast Action
  #--------------------------------------------------------------------------          
  def update_battler_cast_action    
      return unless can_update_cast_action? 
      self.battler.cast_action[3] += 1
      if self.battler.cast_action[3] > XAS_ANIMATION::LOOP_ANIMATIONS_SPEED
         self.battler.cast_action[3] = 0 
         self.animation_id =  self.battler.cast_action[2]
      end  
      self.battler.cast_action[4] += 1 
      if self.battler.cast_action[4] >= self.battler.cast_action[1]
          self.shoot(self.battler.cast_action[0])
      end
  end  
  
  #--------------------------------------------------------------------------
  # ● Can Update Cast Action
  #--------------------------------------------------------------------------            
  def can_update_cast_action? 
      return false if self.battler.cast_action[1] == 0    
      return false if @stop
      return true
  end
  
  #--------------------------------------------------------------------------
  # ● Can Blow Effect
  #--------------------------------------------------------------------------              
  def can_blow? 
      return false if self.stop and not self.battler.state_sleep
      return false if self.battler.no_knockback    
      return false if self.is_a?(Game_Player) and self.action != nil
      return true
  end   
    
  #--------------------------------------------------------------------------
  # ● Blow Effect
  #--------------------------------------------------------------------------        
  def blow(d, power = 1)
      return unless can_blow? 
      jump(0,0)
      self.battler.invunerable_duration = self.battler.knockback_duration if self.battler.invunerable_duration <= 0
      if self.is_a?(Game_Event)
         @collision_attack = false  
      end
      @knock_back_duration = self.battler.knockback_duration 
      refresh_sensor if self.is_a?(Game_Event)
      pre_direction = self.direction
      pre_direction_fix = self.direction_fix
      self.turn_reverse(d)      
      self.direction_fix = true
      power.times do
        case d 
           when 2; @y += 1 if passable?(@x, @y, d)
           when 4; @x -= 1 if passable?(@x, @y, d)
           when 6; @x += 1 if passable?(@x, @y, d)
           when 8; @y -= 1 if passable?(@x, @y, d)
        end
      end
      self.direction_fix = pre_direction_fix
      self.direction = pre_direction
  end
  
  #--------------------------------------------------------------------------
  # ● Can Stop Battler Movement
  #--------------------------------------------------------------------------            
  def can_stop_battler_movement?
      return false if self.dead?   
      return true if self.battler.state_sleep
      return false if self.battler.state_stop
      return false
  end  
  
  #--------------------------------------------------------------------------
  # ● Impact
  #--------------------------------------------------------------------------              
  def impact(enable = true)
      return if self.tool_id == 0
      return if self.action == nil
      self.action.impact = enable
  end
  
  #--------------------------------------------------------------------------
  # ● Update Battler Stop Movement
  #--------------------------------------------------------------------------              
  def update_battler_stop_movement 
      unless can_stop_battler_movement?
          @stop = false   
          return
      end
      @knock_back_duration = nil
      @stop = true      
      @step_anime = false    
      reset_battler_temp
      if self.battler.state_sleep
         make_pose("_Hit", 2)   
      else
         make_pose("", 2) 
      end  
      if self.is_a?(Game_Event)
         @collision_attack = false
      end  
  end
    
  #--------------------------------------------------------------------------
  # ● Update Attacking
  #--------------------------------------------------------------------------              
  def update_battler_attacking 
      return unless can_update_attacking?
      make_pose("_ATK", 2) 
  end

  #--------------------------------------------------------------------------
  # ● Can Update Attacking
  #--------------------------------------------------------------------------              
  def can_update_attacking?
      return false if self.battler.is_a?(Game_Actor)
      return false if @collision_attack == false  
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Battler Knobacking
  #--------------------------------------------------------------------------            
  def update_battler_knockbacking
       return unless self.knockbacking?
       @pattern = 0
       @knock_back_duration -= 1 if can_remove_knockback?
       make_pose("_Hit", 2)        
       if self.is_a?(Game_Event)
          @collision_attack = false
       end         
       if @knock_back_duration <= 0
          @knock_back_duration = nil
          make_pose("", 0) 
          touch_attack(false) if self.is_a?(Game_Event)
          @character_name = @x_pose_original_name
       end
  end  
    
  #--------------------------------------------------------------------------
  # ● Can Remove Knockback
  #--------------------------------------------------------------------------              
  def can_remove_knockback?
      return true
  end

  #--------------------------------------------------------------------------
  # ● knockbacking?
  #--------------------------------------------------------------------------            
  def knockbacking?
      return false if self.battler == nil
      return false if @stop
      return true if @knock_back_duration != nil
      return false
  end

  #--------------------------------------------------------------------------
  # ● collapsing?
  #--------------------------------------------------------------------------          
  def collapsing?
      return self.collapse_duration.to_i > 0
  end
    
  #--------------------------------------------------------------------------
  # ● Seal Effect
  #--------------------------------------------------------------------------          
  def seal_effect
      Sound.play_buzzer
      if XAS_WORD::ENABLE_WORD
         self.battler.damage = XAS_WORD::SEAL
         self.battler.damage_pop = true
      end   
  end    
  
end

#===============================================================================
# ■ XAS_DamageStop
#===============================================================================
module XAS_DamageStop
  
  #--------------------------------------------------------------------------
  # ● Acting
  #--------------------------------------------------------------------------             
  def acting?
      return (super or self.knockbacking? or self.collapsing? or self.stop)
  end
end

#===============================================================================
# ■ Game_Player
#===============================================================================
class Game_Player < Game_Character
      include XAS_DamageStop
end

#===============================================================================
# ■ Game_Event
#===============================================================================
class Game_Event < Game_Character
      include XAS_DamageStop
end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - TOUCH EFFECT
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ XRXS_BattlerAttachment
#==============================================================================
module XRXS_BattlerAttachment 
  
  #--------------------------------------------------------------------------
  # ● Attack Effect
  #--------------------------------------------------------------------------    
  def attack_effect(attacker)
      return false unless $game_system.xas_battle    
      return if self.battler == nil or attacker == nil
      return unless can_attack_effect?(attacker)
      if target_shield_enabled?(attacker, nil, nil)
         execute_guard_effect(attacker, nil, nil, 30)
         return 
      end   
      execute_attack_effect(attacker)
 end
    
 #--------------------------------------------------------------------------
 # ● Can Attack Effect
 #--------------------------------------------------------------------------     
 def can_attack_effect?(attacker)
     return false if self.can_update == false
     return false if @knock_back_duration != nil 
     return false if attacker.stop
     return false if self.battler.invunerable
     return false if self.battler.invunerable_duration > 0
     return false if self.action != nil and self.action.user_invincible
     return false if seal_attack?(attacker.battler)     
     return false if target_state_invunerable?(30)
     return true
 end  
  
 #--------------------------------------------------------------------------
 # ● Attack Target Shield
 #--------------------------------------------------------------------------     
 def attack_target_shield?(attacker)
     return false if attacker.battler.ignore_shield   
     return false unless self.battler.shield
     return true if face_direction?(attacker)
     return false
 end  
 
 #--------------------------------------------------------------------------
 # ● Seal Attack?
 #--------------------------------------------------------------------------               
 def seal_attack?(attacker)
     if attacker.state_seal_attack or attacker.state_mute
        attacker.damage = XAS_WORD::SEAL
        attacker.damage_pop = true
        self.battler.invunerable_duration = self.battler.knockback_duration
        return true 
     end 
     return false
 end   
 
 #--------------------------------------------------------------------------
 # ● Execute Attack Damage 
 #    ※ 몬스터가 기본공격으로 피격
 #--------------------------------------------------------------------------       
 def execute_attack_damage(attacker)
     #if self.battler.agi > (rand(attacker.battler.agi) * 2)
     #   self.battler.result.missed = true
     #   return
     #end
    unless attacker.battler.state_suicide
      damage = (attacker.battler.atk - self.battler.def).truncate
      damage += rand(attacker.battler.luk * 2).truncate - attacker.battler.luk.truncate
      damage = 0 if damage < 0
      if self.battler.state_life && self.battler.hp <= damage
        damage = self.battler.hp - 1
      end
      if attacker.battler.state_drain
        attacker.battler.hp += damage
        attacker.battler.damage = -damage
        attacker.battler.damage_pop = true
      end
      self.battler.result.hp_damage = damage
      #self.battler.result.critical   
      self.battler.hp -= damage.abs
      if self.battler.hp < ( self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100 )
        $game_map.screen.start_flash(Color.new(255, 0, 0), 8)
      else
        $game_map.screen.start_flash(Color.new(255, 0, 0, 50), 8)
      end
      self.battler.attack_apply( attacker.battler )
    else
      damage = (attacker.battler.atk - attacker.battler.def).truncate
      damage += rand(attacker.battler.luk * 2).truncate - attacker.battler.luk.truncate
      damage = 0 if damage < 0
      if attacker.battler.state_life && attacker.battler.hp <= damage
        damage = attacker.battler.hp - 1
      end
      if attacker.battler.state_drain
        attacker.battler.hp += damage
        attacker.battler.result.hp_damage = damage
      end
      attacker.battler.result.hp_damage = damage
      attacker.battler.hp -= damage.abs
      attacker.battler.attack_apply( attacker.battler )
    end
 end
 
 #--------------------------------------------------------------------------
 # ● Execute Attack Effect
 #--------------------------------------------------------------------------      
 def execute_attack_effect(attacker)
     execute_attack_effect_before_damage(attacker)
     execute_attack_damage(attacker)
     if target_missed?(attacker)
#~         self.battler.invunerable_duration = self.battler.knockback_duration
        return 
      end
     attacker.battler.state_suicide ? execute_suicide_damage_pop(attacker) : execute_damage_pop(attacker)
     execute_attack_effect_after_damage(attacker) if can_check_after_attack_effect?(attacker)   
     execute_state_effect(nil, attacker, nil)    
     self.battler.invunerable_duration = 20 + XAS_BA::DEFAULT_KNOCK_BACK_DURATION
     if attacker.battler.attack_animation_id != 0
        self.animation_id = attacker.battler.attack_animation_id 
     end   
     if self.battler.damage.to_i > 0
        self.blow(attacker.direction, 1) if can_blow_effect?
     end
     if self.is_a?(Game_Player)
        self.need_refresh = true
     end
 end  
     
 #--------------------------------------------------------------------------
 # ● Can Check After Attack Effect?  
 #--------------------------------------------------------------------------        
 def can_check_after_attack_effect?(attacker)   
     return false unless self.battler.damage.is_a?(Numeric) 
     return true
 end
 
 #--------------------------------------------------------------------------
 # ● Execute Attack Effect Before Damage
 #--------------------------------------------------------------------------       
 def execute_attack_effect_before_damage(attacker)
 
 end
 
 #--------------------------------------------------------------------------
 # ● Execute Attack Effect After Damage
 #--------------------------------------------------------------------------       
 def execute_attack_effect_after_damage(attacker)
 
 end 
 
#--------------------------------------------------------------------------
# ● Attack Drain Effect
#--------------------------------------------------------------------------
def attack_drain_effect(attacker)
    return if attacker.battler.state_drain == false
    drain_state_damage = self.battler.damage.to_i * XAS::DRAIN_RECOVER_PERC / 100 
    drain_state_damage = 1 if drain_state_damage  < 1
    attacker.battler.damage = -drain_state_damage
    attacker.battler.damage_pop = true         
    attacker.battler.hp += drain_state_damage           
end

#--------------------------------------------------------------------------  
# ● Attack Blow Effect 
#--------------------------------------------------------------------------
def attack_blow_effect(attacker)
    return if self.battler.is_a?(Game_Actor) and not
          ($game_temp.hook_x == 0 and $game_temp.hook_y == 0)    
    unless attacker.battler.e_ignore_hero_shield
           return if self.action != nil
    end
    unless self.action != nil and self.is_a?(Game_Player) and not
   (self.battler.state_sleep or self.battler.stop)      
     if self.battler.damage.to_i > 0
        attack_drain_effect(attacker)                  
        attack_blow_pw = XAS_BA_ENEMY::ATTACK_BLOW_POWER[attacker.battler.id] 
        if attack_blow_pw != nil 
           self.blow(attacker.direction, attack_blow_pw) 
        else
           self.blow(attacker.direction, 1)       
        end
     end      
   end
end
 
end

#===============================================================================
# ■ Game Player
#===============================================================================
class Game_Player < Game_Character  
  #--------------------------------------------------------------------------
  # ● Check Event Trigger Touch
  #--------------------------------------------------------------------------             
  alias xrxs64c_check_event_trigger_touch check_event_trigger_touch
  def check_event_trigger_touch(x, y)
      xrxs64c_check_event_trigger_touch(x, y)
      if $game_map.interpreter.running?
         return
      end
      for event in $game_map.events.values
          next unless event.collision_attack
          unless [1,2].include?(event.trigger)
             if event.battler != nil and event.x == x and event.y == y
                $game_player.attack_effect(event)
             end
          end
      end
  end
  
  #-----------------------------------------------------------------------------
  # ● Check Event Trigger Touch Front
  #-----------------------------------------------------------------------------
  alias xrxs64c_move_straight move_straight
  def move_straight(d, turn_ok = true)
    xrxs64c_move_straight( d, turn_ok )
    for event in $game_map.events.values
      next unless event.collision_attack
      if ( event.battler != nil ) && ( ( event.x - x ).abs + ( event.y - y ).abs <= event.body_size )
        $game_player.attack_effect( event )
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # ● Check Event Trigger Touch Region
  #-----------------------------------------------------------------------------
  alias xrxs64c_move_toward_player move_toward_player
  def move_toward_player
    for event in $game_map.events.values
      next unless event.collision_attack
      if ( event.battler != nil ) && ( event.x == x ) && ( event.y == y )
        $game_player.attack_effect( event )
      end
    end
    xrxs64c_move_toward_player
  end
  
end

#===============================================================================
# ■ Game Event
#===============================================================================
class Game_Event < Game_Character
  
  #--------------------------------------------------------------------------
  # ● Check Event Trigger Touch
  #--------------------------------------------------------------------------             
  alias xrxs64c_check_event_trigger_touch check_event_trigger_touch
  def check_event_trigger_touch(x, y)
    xrxs64c_check_event_trigger_touch(x, y)
    if $game_map.interpreter.running?
       return
    end
    return unless self.collision_attack
    if self.battler != nil and x == $game_player.x and y == $game_player.y
       $game_player.attack_effect(self)
    end
  end
  
  #-----------------------------------------------------------------------------
  # ● Check Event Trigger Touch Front
  #-----------------------------------------------------------------------------
  alias xrxs64c_move_straight move_straight
  def move_straight( d, turn_ok = true )
    xrxs64c_move_straight( d, turn_ok )
    if self.collision_attack
      if ( self.battler != nil ) && ( ( x - $game_player.x ).abs + ( y - $game_player.y ).abs <= self.body_size )
        $game_player.attack_effect( self )
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # ● Check Event Trigger Touch Region
  #-----------------------------------------------------------------------------
  alias xrxs64c_move_toward_player move_toward_player
  def move_toward_player
    if self.collision_attack
      if ( self.battler != nil ) && ( x == $game_player.x ) && ( y == $game_player.y )
        $game_player.attack_effect( self )
      end
    end
    xrxs64c_move_toward_player
  end
  
end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - MOVE SPEED
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#==============================================================================
# ■ Game_Character
#==============================================================================
class Game_Character < Game_CharacterBase
  
  include XAS_BA
  attr_accessor :base_move_speed
  attr_accessor :dash_move_speed
  attr_accessor :move_speed
#~   attr_accessor :agi_speed
  
 #--------------------------------------------------------------------------
 # ● Initialize
 #--------------------------------------------------------------------------  
  alias x_move_speed_initialize initialize 
  def initialize
      @base_move_speed = BASE_MOVE_SPEED
      @dash_move_speed = 0
      @agi_speed = 0
      x_move_speed_initialize
  end  
 
 #--------------------------------------------------------------------------
 # ● update_battler_move_speed
 #--------------------------------------------------------------------------
  def update_battler_move_speed
      @dash_move_speed = @dash_active ? DASH_MOVE_SPEED : 0
      sp1 = @base_move_speed
      sp2 = @dash_move_speed
      sp3 = self.battler.state_move_speed
      if self.is_a?(Game_Player)
      sp4 = $game_party.members[0].agi.to_f / 100
      else
      sp4 = 0
      end
      @move_speed = (sp1 + sp2 + sp3 + sp4)
  end
  
 #--------------------------------------------------------------------------
 # ● Update Animation
 #--------------------------------------------------------------------------      
  def update_animation
      super
      update_force_move_routine_move
  end 
    
 #--------------------------------------------------------------------------
 # ● Update Force Move Routine Move
 #--------------------------------------------------------------------------        
  def update_force_move_routine_move
      return if @force_action == ""
      return if @move_route == nil
      command = @move_route.list[@move_route_index]
      return if command == nil
      if command.code == ROUTE_PLAY_SE    
         params = command.parameters
         params[0].play 
         advance_move_route_index
      end   
  end
 
 #--------------------------------------------------------------------------
 # ● Update Routine Move
 #--------------------------------------------------------------------------      
 alias x_update_routine_move update_routine_move
 def update_routine_move
     return if @force_action_times > 0
     x_update_routine_move
 end
 
 #--------------------------------------------------------------------------
 # ● Can Cancel Move Type Custom
 #--------------------------------------------------------------------------    
  alias x_move_speed_process_move_command process_move_command
  def process_move_command(command)
      return if can_cancel_move_type_custom?(command)
      params = command.parameters
      x_move_speed_process_move_command(command)
      if command.code == ROUTE_CHANGE_SPEED and @battler != nil and 
         self.is_a?(Game_Event)
         @base_move_speed = params[0]
      end        
  end
  
 #--------------------------------------------------------------------------
 # ● Can Cancel Move Type Custom
 #--------------------------------------------------------------------------    
  def can_cancel_move_type_custom?(command)
      return true if command == nil
      return true if @force_action_times > 0
      return false
  end  
        
end  

#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event < Game_Character  
  
 #--------------------------------------------------------------------------
 # ● Initialize
 #--------------------------------------------------------------------------              
 alias x_move_speed_event_initialize initialize
 def initialize(map_id, event)
     x_move_speed_event_initialize(map_id, event)
     refresh_move_speed 
 end  
 
  #--------------------------------------------------------------------------
  # ● Refresh Move Speed
  #--------------------------------------------------------------------------
  def refresh_move_speed
      return if @page == nil 
      @base_move_speed = @page.move_speed
  end 
 
 #--------------------------------------------------------------------------
 # ● Setup Page
 #--------------------------------------------------------------------------               
 alias x_move_speed_setup_page setup_page
 def setup_page(new_page)
     x_move_speed_setup_page(new_page)
     refresh_move_speed
 end
 
end


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - STATES
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase

  attr_accessor :state_move_speed
  attr_accessor :state_stop
  attr_accessor :state_loop_effect_time
  attr_accessor :state_loop_speed
  attr_accessor :state_duration 
  attr_accessor :state_string
  attr_accessor :state_string_time
  attr_accessor :state_stop 
  attr_accessor :state_slow 
  attr_accessor :state_sleep
  attr_accessor :state_invunerable
  attr_accessor :state_fast 
  attr_accessor :state_mute 
  attr_accessor :state_seal_attack 
  attr_accessor :state_seal_skill 
  attr_accessor :state_seal_item 
  attr_accessor :state_puppet
  attr_accessor :state_suicide
  attr_accessor :state_reflect
  attr_accessor :state_death_count
  attr_accessor :state_life
  attr_accessor :state_drain
  attr_accessor :state_berserk
  attr_accessor :state_confuse
  attr_accessor :state_c_confuse
  attr_accessor :state_ct_up
  attr_accessor :state_ct_down
  attr_accessor :state_invisible
  attr_accessor :state_blind
  attr_accessor :state_muddy
  
 #--------------------------------------------------------------------------
 # ● Initialize
 #--------------------------------------------------------------------------  
  alias x_state_initialize initialize
  def initialize
      @state_move_speed = 0
      @state_duration = []
      @state_loop_effect_time = []
      @state_loop_speed = []
      @state_string = ""
      @state_string_time = 0
      @state_stop = false
      @state_sleep = false
      @state_invunerable = false
      @state_slow = false 
      @state_fast = false 
      @state_mute = false 
      @state_seal_attack = false 
      @state_seal_skill = false 
      @state_seal_item = false
      @state_puppet = false 
      @state_suicide = false 
      @state_reflect = false
      @state_death_count = true
      @state_life = false
      @state_drain = false
      @state_berserk = false
      @state_confuse = false
      @state_c_confuse = false
      @state_ct_up = false
      @state_ct_down = false
      @state_invisible = false
      @state_blind = false
      @state_muddy = false
      x_state_initialize
  end
  #--------------------------------------------------------------------------
  # ● 스테이트의 부가 가능 판정
  #--------------------------------------------------------------------------
  def state_addable?(state_id)
    alive? && $data_states[state_id] && !state_resist?(state_id) &&
      !state_restrict?(state_id) #!state_removed?(state_id) && 
  end
 #--------------------------------------------------------------------------
 # ● Add State
 #--------------------------------------------------------------------------    
  alias x_add_state add_state
  def add_state(state_id)
#~       unless @states.include?(state_id)
      unless @no_damage_pop
          state = $data_states[state_id] 
          if state.note =~ /<Blind>/
            $game_map.screen.start_tone_change(Tone.new(-255, -255, -255), 60)
          elsif state.note =~ /<Muddy>/
            $game_map.screen.start_tone_change(Tone.new(-100, -100, -100), 60)
          end
          xas_add_state(state)
#~       add_new_state(state_id) unless state?(state_id)
#~       reset_state_counts(state_id)
#~       @result.added_states.push(state_id).uniq!
      x_add_state(state_id)
      end   
  end 
 #--------------------------------------------------------------------------
 # ● Xas Add State
 #--------------------------------------------------------------------------      
  def xas_add_state(state)
      @state_duration[state.id] = 60 * $data_states[state.id].min_turns 
      @state_loop_effect_time[state.id] = 0 
      @state_loop_speed[state.id] = $data_states[state.id].max_turns 
      execute_damage_state(state,0)
  end      

 #--------------------------------------------------------------------------
 # ● Remove State
 #--------------------------------------------------------------------------        
  alias x_remove_state remove_state
  def remove_state(state_id)
      if state?(state_id)
         state = $data_states[state_id] 
         if state.note =~ /<Blind>/ || state.note =~ /<Muddy>/
           $game_map.screen.start_tone_change(Tone.new(0, 0, 0), 60)
         end
         xas_remove_state(state)
      end  
      x_remove_state(state_id)      
  end    
  
 #--------------------------------------------------------------------------
 # ● XAS Remove State
 #--------------------------------------------------------------------------         
  def xas_remove_state(state)
      @state_duration[state.id] = 0
      @state_duration.delete(state.id)  
      @state_loop_effect_time.delete(state.id)  
      @state_loop_speed.delete(state.id)
      execute_damage_state(state,1)
  end  
 #--------------------------------------------------------------------------
 # ● Execute_Damage_State
 #--------------------------------------------------------------------------           
  def execute_damage_state(state,type)
      return unless XAS_DAMAGE_POP::DAMAGE_STATE_POP
      return unless XAS_WORD::ENABLE_WORD
      return unless state_addable?(state.id)
      return if state == nil or state.id == 1
      case type
         when 0
             damage = "+ " + state.name.to_s
         when 1  
             damage = "- " + state.name.to_s
      end
      @state_string = damage
      @state_string_time = 30             
  end  
  
end

#==============================================================================
# ■ Game_Character
#==============================================================================
class Game_Character < Game_CharacterBase
  
 #--------------------------------------------------------------------------
 # ● Update Battler States Effect
 #--------------------------------------------------------------------------    
 def update_battler_states_effect
     return unless XAS_SYSTEM::STATE_SYSTEM
     update_state_string_pop
     update_pre_state_setup
     return unless can_update_states_effect?
     for i in self.battler.states
         state = $data_states[i.id]  
         if state == nil or self.battler.state_duration[state.id] == nil or
            self.battler.state_loop_effect_time[state.id] == nil or
            self.battler.state_loop_speed[state.id] == nil
            self.battler.remove_state(state.id)
            next
            return
         end  
         update_state_abs_effects(state)
         update_state_loop(state)
         update_remove_state(state)
     end  
       
 end  
  
 #--------------------------------------------------------------------------
 # ● Update Pre State Setup
 #--------------------------------------------------------------------------       
 def update_pre_state_setup
     self.battler.state_stop = false
     self.battler.state_slow = false
     self.battler.state_fast = false
     self.battler.state_mute = false
     self.battler.state_sleep = false
     self.battler.state_puppet = false
     self.battler.state_suicide = false
     self.battler.state_invunerable = false
     self.battler.state_seal_attack = false
     self.battler.state_seal_skill = false
     self.battler.state_seal_item = false 
     self.battler.state_reflect = false
     self.battler.state_move_speed = 0
     self.battler.state_death_count = true
     self.battler.state_life = false
     self.battler.state_drain = false
     self.battler.state_berserk = false
     self.battler.state_confuse = false
     self.battler.state_c_confuse = false
     self.battler.state_ct_up = false
     self.battler.state_ct_down = false
     self.battler.state_invisible = false
     self.battler.state_blind = false
     self.battler.state_muddy = false
 end  
 
 #--------------------------------------------------------------------------
 # ● Update Pre State Setup
 #--------------------------------------------------------------------------        
 def update_state_abs_effects(state)
     if state.note =~ /<Stop>/
        self.battler.state_stop = true
     end
     if state.note =~ /<Slow>/
        self.battler.state_slow = true
        self.battler.state_move_speed = -1.5
     end   
     if state.note =~ /<Fast>/   
        self.battler.state_fast = true
        self.battler.state_move_speed = 1     
     end
     if self.battler.state_fast and
        self.battler.state_slow
        self.battler.state_move_speed = 0
     end
     if state.note =~ /<Mute>/   
        self.battler.state_mute = true
     end
     if state.note =~ /<Sleep>/  
        self.battler.state_sleep = true
     end
     if state.note =~ /<Puppet>/  
        self.battler.state_puppet = true
        move_random unless self.moving?
     end
     if state.note =~ /<Suicide>/  
        self.battler.state_suicide = true
     end
     if state.note =~ /<Invincible>/   
        self.battler.state_invunerable = true
     end  
     if state.note =~ /<Seal Attack>/   
        self.battler.state_seal_attack = true
     end 
     if state.note =~ /<Seal Skill>/   
        self.battler.state_seal_skill = true
     end       
     if state.note =~ /<Seal Item>/   
        self.battler.state_seal_item = true
      end
     if state.note =~ /<Reflect>/
        self.battler.state_reflect = true
     end
     if state.note =~ /<Death Count>/
        self.battler.state_death_count = false
     end
     if state.note =~ /<Life>/
        self.battler.state_life = true
     end
     if state.note =~ /<Drain>/
        self.battler.state_drain = true
     end
     if state.note =~ /<Berserk>/
        self.battler.state_berserk = true
     end
     if state.note =~ /<Confuse>/
        self.battler.state_confuse = true
#~         $game_player.move_by_input_mirror
#~         move_mirror(Input.dir4) if Input.dir4 > 0
#~         move_straight((5 - Input.dir4) * 2 + Input.dir4) if Input.dir4 > 0
     end
     if state.note =~ /<Random Confuse>/
        self.battler.state_c_confuse = true
     end
     if state.note =~ /<CT Up>/
        self.battler.state_ct_up = true
     end
     if state.note =~ /<CT Down>/
        self.battler.state_ct_down = true
     end
     if state.note =~ /<Invisible>/
        self.battler.state_invisible = true
     end
     if state.note =~ /<Blind>/
        self.battler.state_blind = true
     end
     if state.note =~ /<Muddy>/
        self.battler.state_muddy = true
     end
 end
 
 #--------------------------------------------------------------------------
 # ● Update State Loop
 #--------------------------------------------------------------------------      
 def update_state_loop(state)
     self.battler.state_loop_effect_time[state.id] += 1
     if self.battler.state_loop_effect_time[state.id] > self.battler.state_loop_speed[state.id]
        self.battler.state_loop_effect_time[state.id] = 0
        if state.note =~ /<Animation ID = (\d+)>/
           state_anime = $1.to_i
           if state_anime != nil
              self.animation_id = state_anime
           end
        end    
        execute_states_effects(state)          
     end          
  if state.note =~ /<Life>/ && self.battler.hp == 1
    self.animation_id = XAS::RELIFE_ANIMATION_ID
    self.battler.remove_state(20)
  end
 end
 
 #--------------------------------------------------------------------------
 # ● Execute States Effect
 #--------------------------------------------------------------------------       
 def execute_states_effects(state)         
     if state.note =~ /<Slip Damage = (\S+)>/
        execute_state_slip_damage($1.to_i) 
     end  
   if state.note =~ /<Death Count>/
      self.battler.state_duration[state.id] -= 45
      death_number = self.battler.state_duration[state.id] / 100
       if death_number > 0   
         display_damage(XAS::DEATHCOUNT_TEXT_COUNT.to_s + death_number.abs.truncate.to_s) 
      else  
         self.battler.hp = 0 if self.battler.is_a?(Game_Enemy)  
         SceneManager.goto(Scene_Gameover) if self.battler.is_a?(Game_Actor)  
#~          if self.battler.is_a?(Game_Actor)
#~            if self.battler.state_life #and self.battler.hp > 1
#~              self.battler.hp = 1
#~            else
#~              SceneManager.goto(Scene_Gameover)
#~            end
#~          end
      end
   end
     if state.note =~ /<Slip MP Damage = (\S+)>/
        execute_state_mp_slip_damage($1.to_i) 
     end  
 end
 
 #--------------------------------------------------------------------------
 # ● Display Damage
 #--------------------------------------------------------------------------    
 def display_damage(value) 
     self.battler.damage = value
     self.battler.damage_pop = true   
 end  

 #--------------------------------------------------------------------------
 # ● Execute States Slip Damage
 #--------------------------------------------------------------------------        
 def execute_state_slip_damage(damage)
     damage = 1 if damage == nil
     damage_slip = damage #self.battler.mhp * damage / 100
     self.battler.hp -= damage_slip
     self.battler.damage = damage_slip
     self.battler.damage_pop = true
     return if damage <= 0
     if self.battler.hp < ( self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100 )
       $game_map.screen.start_flash(Color.new(255, 0, 0), 8)
     else
       $game_map.screen.start_flash(Color.new(255, 0, 0, 50), 8)
     end
 end
 
 #--------------------------------------------------------------------------
 # ● Execute States Slip Damage
 #--------------------------------------------------------------------------        
 def execute_state_mp_slip_damage(damage)
     damage = 1 if damage == nil
     damage_slip = damage #self.battler.mmp * damage / 100
     self.battler.mp -= damage_slip
     self.battler.damage_type = "Mp"
     self.battler.damage = damage_slip
     self.battler.damage_pop = true
 end
 
 #--------------------------------------------------------------------------
 # ● Update Remove State
 #--------------------------------------------------------------------------       
 def update_remove_state(state)
     self.battler.state_duration[state.id] -= 1
     if self.battler.state_duration[state.id] <= 0     
        self.battler.remove_state(state.id) 
     end          
 end
 
 #--------------------------------------------------------------------------
 # ● Can Update States Effect
 #--------------------------------------------------------------------------      
  def can_update_states_effect?
      return false if self.dead?
      return false if self.battler.states == nil
      return false if self.battler.states.size == 0
      return false if self.battler.state_duration == []
      return true
  end
 #--------------------------------------------------------------------------
 # ● Update State String Pop
 #--------------------------------------------------------------------------       
  def update_state_string_pop
      return false if self.battler.state_string_time == 0
      self.battler.state_string_time -= 1
      if self.battler.state_string_time == 0
         self.battler.damage = self.battler.state_string
         self.battler.damage_pop = true
         self.battler.state_string = ""
      end  
  end  
  
end  

#==============================================================================
# ■ Game_Party
#==============================================================================
#~ class Game_Party < Game_Unit

 #--------------------------------------------------------------------------
 # ● On Player Walk
 #--------------------------------------------------------------------------        
#~  alias x_state_on_player_walk on_player_walk
#~  def on_player_walk
#~      return if XAS_SYSTEM::STATE_SYSTEM
#~      x_state_on_player_walk
#~  end 
 
#~ end 



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - EVENT COMMANDS
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game Event
#===============================================================================
class Game_Event < Game_Character
  
  #--------------------------------------------------------------------------
  # ● Shoot Chance
  #--------------------------------------------------------------------------            
  def shoot_chance(action_id, perc)
      return if self.battler == nil 
      if perc >= rand(100)
         shoot(action_id)
      end  
  end  
  
  #--------------------------------------------------------------------------
  # ● Guard
  #--------------------------------------------------------------------------          
  def guard(enable)
      return if self.battler == nil 
      self.battler.guard = enable
  end  
  
  
  #--------------------------------------------------------------------------
  # ● Touch Attack
  #--------------------------------------------------------------------------             
  def touch_attack(enable)
      return if self.battler == nil        
      return if seal_attack?(self.battler)
      @collision_attack = enable
      @pattern = 0
      @pattern_count  = 0      
  end
  
  #--------------------------------------------------------------------------
  # ● Counter
  #--------------------------------------------------------------------------             
  def counter(enable)
      return if self.battler == nil 
      self.battler.counter_action[2] = enable
  end    
 
  #--------------------------------------------------------------------------
  # ● Rand Shoot
  #--------------------------------------------------------------------------             
  def rand_shoot(random_id = [])
      return if self.battler == nil 
      return if random_id == []
      action_id = random_id[rand(random_id.size)]
      self.shoot(action_id)
  end      

  #--------------------------------------------------------------------------
  # ● Wait
  #--------------------------------------------------------------------------             
  def wait(dur)
      @wait_count = dur
  end      

  #--------------------------------------------------------------------------
  # ● Rand Method
  #--------------------------------------------------------------------------             
  def rand_method(random_id = [])
      return if self.battler == nil 
      return if random_id == []
      random_id[rand(random_id.size)]
  end     

#■XP■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

 #--------------------------------------------------------------------------
 # ● HP Shoot
 #--------------------------------------------------------------------------
  def hp_shoot(hp_high, hp_low, perc)
    return if self.battler == nil
    if rand(100) <= perc
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp >= lowhp
        shoot(hp_high)
      else
        shoot(hp_low)
      end
    end
  end
 #--------------------------------------------------------------------------
 # ● Lowhp Shoot
 #--------------------------------------------------------------------------
  def lowhp_shoot(action_id, perc)
      return if self.battler == nil
      if rand(100) <= perc
        lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
        if self.battler.hp < lowhp
          shoot(action_id)
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Shp Shoot
 #--------------------------------------------------------------------------
  def shp_shoot(hp, action_id, perc)
      return if self.battler == nil
      if rand(100) <= perc
        shp = self.battler.mhp * hp / 100
        if self.battler.hp < shp
          shoot(action_id)
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Fatal Shoot
 #--------------------------------------------------------------------------
  def fatal_shoot(action_id, perc)
      return if self.battler == nil
      if rand(100) <= perc
          shoot(action_id)
          self.battler.damage = self.battler.hp
          self.battler.damage_pop = true
          self.battler.gain_exp_gold = false
          self.battler.hp -= self.battler.hp
      end
  end
 #--------------------------------------------------------------------------
 # ● Lowhp Fatal Shoot
 #--------------------------------------------------------------------------
  def lowhp_fatal_shoot(action_id, perc)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp < lowhp
          if rand(100) <= perc
            shoot(action_id)
            self.battler.damage = self.battler.hp
            self.battler.damage_pop = true
            self.battler.gain_exp_gold = false
            self.battler.hp -= self.battler.hp
          end
      end
  end
 #--------------------------------------------------------------------------
 # ● Lowhp Rand Shoot
 #--------------------------------------------------------------------------
  def lowhp_rand_shoot(random_id = [])
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp < lowhp
        return if random_id == []
        action_id = random_id[rand(random_id.size)]
        self.shoot(action_id)
      end
  end
 #--------------------------------------------------------------------------
 # ● Escape
 #--------------------------------------------------------------------------
  def escape(hp, perc)
      return if self.battler == nil
      if rand(100) <= perc
         self.battler.damage = XAS_ABS_SETUP::ESCAPE_TEXT
         self.battler.damage_pop = true
         self.collapse_done = true
         $data_system.sounds[8].play
         self.erase
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Escape
 #--------------------------------------------------------------------------
  def lowhp_escape(perc)
      return if self.battler == nil
      if rand(100) <= perc
        lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
        if self.battler.hp < lowhp
            self.battler.damage = XAS_ABS_SETUP::ESCAPE_TEXT
            self.battler.damage_pop = true
            self.collapse_done = true
            $data_system.sounds[8].play
            self.erase
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● HP Guard
 #--------------------------------------------------------------------------
  def hp_guard(enable)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp >= lowhp
        self.battler.guard = enable
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Guard
 #--------------------------------------------------------------------------
  def lowhp_guard(enable)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp < lowhp
        self.battler.guard = enable
      else
        self.battler.guard = false
      end
  end
 #--------------------------------------------------------------------------
 # ● Hit Reaction
 #--------------------------------------------------------------------------
  def hit_reaction(enable)
      return if self.battler == nil
      self.battler.no_knockback = enable
  end
 #--------------------------------------------------------------------------
 # ● Hp Hit Reaction
 #--------------------------------------------------------------------------
  def hp_hit_reaction(enable)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp >= lowhp
        self.battler.no_knockback = enable
      else
        if enable == true
          self.battler.no_knockback = false
        else
          self.battler.no_knockback = true
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Switch
 #--------------------------------------------------------------------------
  def lowhp_switch(x, enable)
    return if self.battler == nil
    lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
    if self.battler.hp < lowhp
      $game_switches[x] = enable
      $game_map.need_refresh = true if $game_map.need_refresh == false
      self.refresh
    end
  end
 #--------------------------------------------------------------------------
 # ● HP Switch
 #--------------------------------------------------------------------------
  def hp_switch(x, enable)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp >= lowhp
          $game_switches[x] = enable
          $game_map.need_refresh = true
      else
         if enable == true
          $game_switches[x] = false
         else
          $game_switches[x] = true
         end
         $game_map.need_refresh = true if $game_map.need_refresh == false
      end
  end
 #--------------------------------------------------------------------------
 # ● Anime
 #--------------------------------------------------------------------------
  def anime(anime_id)
      self.animation_id = anime_id    
  end
 #--------------------------------------------------------------------------
 # ● HP Anime
 #--------------------------------------------------------------------------
  def hp_anime(anime_id1, anime_id2)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp >= lowhp
          self.animation_id = anime_id1
      else
          self.animation_id = anime_id2     
      end
  end  
 #--------------------------------------------------------------------------
 # ● LowHP Anime
 #--------------------------------------------------------------------------
  def lowhp_anime(anime_id)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp < lowhp
         self.animation_id = anime_id
      end
  end
 #--------------------------------------------------------------------------
 # ● Speed
 #--------------------------------------------------------------------------
  def speed(x, perc = 100)
      return if self.battler == nil 
      if perc >= rand(100)
         @base_move_speed = x
      end  
  end  
 #--------------------------------------------------------------------------
 # ● HP Speed
 #--------------------------------------------------------------------------
  def hp_speed(x1, x2)
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp >= lowhp
        @base_move_speed = x1
      else
        @base_move_speed = x2
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Speed
 #--------------------------------------------------------------------------
  def lowhp_speed(x)
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if self.battler.hp < lowhp
        @base_move_speed = x
      end
  end
 #--------------------------------------------------------------------------
 # ● Freq
 #--------------------------------------------------------------------------  
  def freq(x)
      @move_frequency = x
  end
 #--------------------------------------------------------------------------
 # ● Add State
 #--------------------------------------------------------------------------
  def add_state(states_id, perc)
      return if self.battler == nil
      if rand(100) <= perc
         self.battler.add_state(states_id)
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Add State
 #--------------------------------------------------------------------------
  def lowhp_add_state(states_id, perc)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if rand(100) <= perc
         if self.battler.hp < lowhp
            self.battler.add_state(states_id) 
         end
      end
  end
 #--------------------------------------------------------------------------
 # ● Remove State
 #--------------------------------------------------------------------------
  def remove_state(states_id, perc)
      return if self.battler == nil
      if rand(100) <= perc
        self.battler.remove_state(states_id)
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Remove State
 #--------------------------------------------------------------------------
  def lowhp_remove_state(states_id, perc)
      return if self.battler == nil
      lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
      if rand(100) <= perc
         if self.battler.hp < lowhp
            self.battler.remove_state(states_id)
         end
      end
  end
 #--------------------------------------------------------------------------
 # ● Self Damage
 #--------------------------------------------------------------------------
  def self_damage(damage, perc)
      return if self.battler == nil
      if rand(100) <= perc
         self.battler.damage = damage.to_i
         self.battler.damage_pop = true              
         self.battler.hp -= damage
         if self.battler.hp <= 0 
#~             self.battler.exp = 0
         end
      end
  end
 #--------------------------------------------------------------------------
 # ● Recover All
 #--------------------------------------------------------------------------
  def recover_all(perc)
      return if self.battler == nil
      if rand(100) <= perc
         self.battler.damage = "전체 회복"
         self.battler.damage_pop = true
         self.battler.recover_all
      end
  end
 #--------------------------------------------------------------------------
 # ● LowHP Recover All
 #--------------------------------------------------------------------------
  def lowhp_recover_all(perc)
      return if self.battler == nil
      if rand(100) <= perc
        lowhp = self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100
        if self.battler.hp < lowhp
          self.battler.damage = "전체 회복"
          self.battler.damage_pop = true
          self.battler.recover_all
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Text
 #--------------------------------------------------------------------------
  def text(tx, perc)
      return if self.battler == nil
      if rand(100) <= perc
        self.battler.damage = tx.to_s
        self.battler.damage_pop = true
      end
  end
 #--------------------------------------------------------------------------
 # ● Zoom
 #--------------------------------------------------------------------------
  def zoom(x, y)
      return if self.battler == nil
      @zoom_x = x
      @zoom_y = y
  end
 #--------------------------------------------------------------------------
 # ● Body Zoom
 #--------------------------------------------------------------------------
  def body_zoom(size)
      return if self.battler == nil
      self.battler.body_size = size
  end
 #--------------------------------------------------------------------------
 # ● Hero LOWHP Shoot
 #--------------------------------------------------------------------------
  def hero_lowhp_shoot(action_id, perc)
      actor = $game_party.members[0]
      if rand(100) <= perc
        lowhp = actor.mhp * XAS_BA_ENEMY::LOWHP / 100
        if actor.hp < lowhp
           shoot(action_id)
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero LowHP Switch
 #--------------------------------------------------------------------------
  def hero_lowhp_switch(x, enable)
      actor = $game_party.members[0]
      lowhp = actor.mhp * XAS_BA_ENEMY::LOWHP / 100
      if actor.hp < lowhp
          $game_switches[x] = enable
          $game_map.need_refresh = true if $game_map.need_refresh == false
          self.refresh
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero HP Shoot
 #--------------------------------------------------------------------------
  def hero_hp_shoot(hp_high, hp_low, perc)
      actor = $game_party.members[0]
    if rand(100) <= perc
       lowhp = actor.mhp * XAS_BA_ENEMY::LOWHP / 100
       if actor.hp >= lowhp
          shoot(hp_high)
       else
          shoot(hp_low)
       end
    end
  end
 #--------------------------------------------------------------------------
 # ● Hero HP Switch
 #--------------------------------------------------------------------------
  def hero_hp_switch(x, enable)
      actor = $game_party.members[0]
      lowhp = actor.mhp * XAS_BA_ENEMY::LOWHP / 100
      if actor.hp >= lowhp
          $game_switches[x] = enable
          $game_map.need_refresh = true
      else
         if enable == true
          $game_switches[x] = false
         else
          $game_switches[x] = true
         end
         $game_map.need_refresh = true if $game_map.need_refresh == false
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero HP Anime
 #--------------------------------------------------------------------------
  def hero_hp_anime(anime_id1, anime_id2)
      actor = $game_party.members[0]
      lowhp = actor.mhp * XAS_BA_ENEMY::LOWHP / 100
      if actor.hp >= lowhp
        self.animation_id = anime_id1
      else
        self.animation_id = anime_id2
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Switch
 #--------------------------------------------------------------------------
  def hero_level_switch(x, level, enable)
      actor = $game_party.members[0]
      if actor.level >= level
          $game_switches[x] = enable
          $game_map.need_refresh = true if $game_map.need_refresh == false
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Shoot
 #--------------------------------------------------------------------------
  def hero_level_shoot(action_id1, action_id2, level, perc)
      if rand(100) <= perc
        actor = $game_party.members[0]
        if actor.level >= level
           shoot(action_id1)
        else
           shoot(action_id2)
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Speed
 #--------------------------------------------------------------------------
  def hero_level_speed(x1, x2, level)
      actor = $game_party.members[0]
      if actor.level >= level
        @base_move_speed = x1
      else
        @base_move_speed = x2
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Escape
 #--------------------------------------------------------------------------
  def hero_level_escape(level, perc)
      return if self.battler == nil
      if rand(100) <= perc
        actor = $game_party.members[0]
        if actor.level >= level
            self.battler.no_damage = true
            self.battler.damage = "도주"
            self.battler.damage_pop = true
            self.collapse_done = true
            $data_system.sounds[8].play
            self.erase
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Guard
 #--------------------------------------------------------------------------
  def hero_level_guard(level, enable)
      return if self.battler == nil
      actor = $game_party.members[0]
      if actor.level >= level
        self.battler.guard = enable
      else
        self.battler.guard = false
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Hit Reaction
 #--------------------------------------------------------------------------
  def hero_level_hit_reaction(level, enable)
      return if self.battler == nil
      actor = $game_party.members[0]
      if actor.level >= level
        self.battler.no_knockback = enable
      else
        if enable == true
          self.battler.no_knockback = false
        else
          self.battler.no_knockback = true
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● Hero Level Anime
 #--------------------------------------------------------------------------
  def hero_level_anime(anime_id1, anime_id2, level)
      actor = $game_party.members[0]
      if actor.level >= level
        self.animation_id = anime_id1
      else
        self.animation_id = anime_id2
      end
  end
 #--------------------------------------------------------------------------
 # ● Jump Near
 #--------------------------------------------------------------------------
  def jump_near
      if $game_player.x > self.x and
         $game_player.y > self.y
         range_x = $game_player.x - self.x
         range_y = -1 + $game_player.y - self.y
      elsif $game_player.x < self.x and
         $game_player.y < self.y
         range_x = $game_player.x - self.x
         range_y = 1 + $game_player.y - self.y
      elsif $game_player.x > self.x and
         $game_player.y < self.y
         range_x = $game_player.x - self.x
         range_y = 1 + $game_player.y - self.y
      elsif $game_player.x < self.x and
         $game_player.y > self.y
         range_x = $game_player.x - self.x
         range_y = -1 + $game_player.y - self.y
      elsif $game_player.x < self.x and
         $game_player.y == self.y
         range_x = 1 + $game_player.x - self.x
         range_y = $game_player.y - self.y
      elsif $game_player.x > self.x and
         $game_player.y == self.y
         range_x = -1 + $game_player.x - self.x
         range_y = $game_player.y - self.y
      elsif $game_player.x == self.x and
         $game_player.y > self.y
         range_x = $game_player.x - self.x
         range_y = -1 + $game_player.y - self.y
      elsif $game_player.x == self.x and
         $game_player.y < self.y
         range_x = $game_player.x - self.x
         range_y = 1 + $game_player.y - self.y
     else
         range_x = 0
         range_y = 0
      end
         jump(range_x,range_y) unless range_y == 0 and range_x == 0
  end
 #--------------------------------------------------------------------------
 # ● Jump Org
 #--------------------------------------------------------------------------
  def jump_org
      range_x = old_x - self.x
      range_y = old_y - self.y
      jump(range_x,range_y)
  end      
 #--------------------------------------------------------------------------
 # ● SelfHP Shoot
 #--------------------------------------------------------------------------
  def selfhp_shoot(selfhp, selfhp_high, selfhp_low, perc)
    return if self.battler == nil
    if rand(100) <= perc
      vhp = self.battler.mhp * selfhp / 100
      if self.battler.hp >= vhp
        shoot(selfhp_high)
      else
        shoot(selfhp_low)
      end
    end
  end
 #--------------------------------------------------------------------------
 # ● LowSelfHP Shoot
 #--------------------------------------------------------------------------
  def lowselfhp_shoot(selfhp, action_id, perc)
      return if self.battler == nil
      if rand(100) <= perc
        vhp = self.battler.mhp * selfhp / 100
        if self.battler.hp < vhp
          shoot(action_id)
        end
      end
  end
 #--------------------------------------------------------------------------
 # ● LowSelfHP Switch
 #--------------------------------------------------------------------------
  def lowselfhp_switch(selfhp, x, enable)
    return if self.battler == nil
    vhp = self.battler.mhp * selfhp / 100
    if self.battler.hp < vhp
      $game_switches[x] = enable
      $game_map.need_refresh = true if $game_map.need_refresh == false
      self.refresh
    end
  end

end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - DEFEAT PROCESS
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

#===============================================================================
# ■ Scene Base
#===============================================================================
class Scene_Base  
  
  #--------------------------------------------------------------------------
  # ● Check Gameover
  #--------------------------------------------------------------------------              
  def check_gameover
      return unless $game_party.in_battle
      SceneManager.goto(Scene_Gameover) if $game_party.all_dead?
  end
end  

#===============================================================================
# ■ Game Character
#===============================================================================
class Game_Character < Game_CharacterBase
  attr_accessor :collapse_duration
  attr_accessor :collapse_duration_save
  attr_accessor :collapse_duration
  attr_accessor :gain_duration
  attr_writer   :opacity
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------            
  alias x_collapse_initialize initialize
  def initialize
      @collapse_duration = 0
      @collapse_duration_save = 0
      @gain_duration = 0
      x_collapse_initialize
  end  
  
end

#===============================================================================
# ■ XAS_BA_BATTLEEVENT_NONPREEMPT
#==============================================================================
module XAS_BA_BATTLEEVENT_NONPREEMPT
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------             
  def update
      return if self.battler != nil and $game_map.interpreter.running?
      super
  end
end

#===============================================================================
# ■ Game Event
#==============================================================================
class Game_Event < Game_Character
      include XAS_BA_BATTLEEVENT_NONPREEMPT
end

#===============================================================================
# ■ Game Character
#===============================================================================
class Game_Character < Game_CharacterBase

  #--------------------------------------------------------------------------
  # ● Update Battler Defeat Process
  #--------------------------------------------------------------------------      
   def update_battler_defeat_process
       execute_enemy_defeated_process if can_check_enemy_defeated?
       execute_actor_defeated_process if can_check_actor_defeated?
   end
   
  #--------------------------------------------------------------------------
  # ● Can Check Enemy Defeated?
  #--------------------------------------------------------------------------            
  def can_check_enemy_defeated?  
      return false if self.battler.is_a?(Game_Actor)
      return false if self.battler.defeated
      return true
  end     
  
  #--------------------------------------------------------------------------
  # ● Can Check Actor Defeated?
  #--------------------------------------------------------------------------              
  def can_check_actor_defeated?
      return false if self.battler.is_a?(Game_Enemy)
      return false if self.battler.defeated
      return false if $game_party.members[0].hp > 0
      return false if @collapse_duration > 0
      return true  
  end
  
  #--------------------------------------------------------------------------
  # ● Execute Actor Defeated Process
  #--------------------------------------------------------------------------                
  def execute_actor_defeated_process
      erase_actor_tools_on_map
      if $game_party.all_dead? and not self.battler.defeated
         self.battler.defeated = true
         self.collapse_duration = 120
         self.knock_back_duration = 161
         self.battler.defeated = false
         reset_battler_temp
      else   
         $game_temp.change_leader_wait_time = 0
         $game_player.change_leader
      end  
  end
  
  #--------------------------------------------------------------------------
  # ● Erase Tools on Map
  #--------------------------------------------------------------------------                  
  def erase_actor_tools_on_map
      for event in $game_map.events.values
          if event.tool_id > 0 and event.action.user.is_a?(Game_Player)
             event.erase
          end   
      end  
  end
  
  #--------------------------------------------------------------------------
  # ● Execute Enemy Defeaed Process
  #--------------------------------------------------------------------------         
   def execute_enemy_defeated_process
       self.battler.defeated = true
       self.through = true
       @knock_back_duration = 121
       enemy = $data_enemies[self.battler.enemy_id]
       if self.name =~ /<UNSPAWN>/
         $game_troop.events_respawn_time[$game_troop.events_respawn_time.size] = [ @map_id, self.id, -1 ]
       else
        if enemy.note =~ /<리스폰 [:=] (\d+)>/
          st = $1.to_i
          unless self.name =~ /<NORESPAWN>/
            $game_troop.events_respawn_time[$game_troop.events_respawn_time.size] = [ @map_id, self.id, ( st * 100 / 6 ).to_i ]
          else
            $game_troop.events_respawn_time[$game_troop.events_respawn_time.size] = [ @map_id, self.id, 0 ]
          end
        else
          $game_troop.events_respawn_time[$game_troop.events_respawn_time.size] = [ @map_id, self.id, 0 ]
        end
       end
       @collapse_duration = self.battler.collapse_duration_t
       @collapse_duration_save = self.battler.collapse_duration_t
       execute_gain_exp_gold(enemy)  
       execute_active_switch(enemy)
       execute_defeated_animation(enemy)
       execute_defeated_sound_effect(enemy)
       execute_final_shoot(enemy)
       
       $game_system.quest.ids.each do |id|
         data = $game_system.quest[id]
         next unless data.visible
         if data.playing #and !data.quest_clear? and !data.alarm
           for i in 0...data.condition.size
             if data.condition[i].type == 7 and data.condition[i].id == enemy.id
                 $game_temp.event_window_data2 = [] if $game_temp.event_window_data2.nil?
                 if $game_temp.event_window_data2 != []
                   for j in 0...$game_temp.event_window_data2.size
                     next if $game_temp.event_window_data2[ j ] == nil
                     $game_temp.event_window_data2[ j ] = nil if ( $game_temp.event_window_data2[ j ].include?( "\ec[27]#{data.name}\ec[0] : \ec[10]#{enemy.name}" ) ) || ( !$game_temp.event_window_data2[ j ].include?( "\ec[18]" ) )
                   end
                   $game_temp.event_window_data2.compact!
                 end
                 $game_temp.event_window_data2.each do |j|
                   $game_temp.event_window_data2.delete(j) if j.include?("\ec[27]#{data.name}\ec[0] : \ec[10]#{enemy.name}") or !j.include?("\ec[18]")
                 end
               if (defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) : 0) == data.condition[i].num
                 SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[24]#{data.name}\ec[0] : \ec[10]#{enemy.name} \ec[24]#{(defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) : 0).to_s}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]"+YEA::EVENT_WINDOW2::CLOSER_TEXT)
                 Audio.se_play("Audio/SE/Chime2", 100, 100)
               elsif (defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) : 0) < data.condition[i].num
                 SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[27]#{data.name}\ec[0] : \ec[10]#{enemy.name} \ec[18]#{(defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) : 0).to_s}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]"+YEA::EVENT_WINDOW2::CLOSER_TEXT)
               end
             elsif data.condition[i].type == 13 and data.condition[i].id == enemy.id
                 $game_temp.event_window_data2 = [] if $game_temp.event_window_data2.nil?
                 if $game_temp.event_window_data2 != []
                   for j in 0...$game_temp.event_window_data2.size
                     next if $game_temp.event_window_data2[ j ] == nil
                     $game_temp.event_window_data2[ j ] = nil if ( $game_temp.event_window_data2[ j ].include?( "\ec[27]#{data.name}\ec[0] : \ec[10]#{enemy.name}" ) ) || ( !$game_temp.event_window_data2[ j ].include?( "\ec[18]" ) )
                   end
                   $game_temp.event_window_data2.compact!
                 end
                 $game_temp.event_window_data2.each do |j|
                   $game_temp.event_window_data2.delete(j) if j.include?("\ec[27]#{data.name}\ec[0] : \ec[10]#{enemy.name}") or !j.include?("\ec[18]")
                 end
               if (defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) - data.enemy_dn[enemy.id] : 0) == data.condition[i].num
                 SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[24]#{data.name}\ec[0] : \ec[10]#{enemy.name} \ec[24]#{(defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) - data.enemy_dn[enemy.id] : 0).to_s}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]"+YEA::EVENT_WINDOW2::CLOSER_TEXT)
                 Audio.se_play("Audio/SE/Chime2", 100, 100)
               elsif (defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) - data.enemy_dn[enemy.id] : 0) < data.condition[i].num
                 SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[27]#{data.name}\ec[0] : \ec[10]#{enemy.name} \ec[18]#{(defined?(DefeatCounter) ? $game_actors.defeat_all(enemy.id) - data.enemy_dn[enemy.id] : 0).to_s}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]"+YEA::EVENT_WINDOW2::CLOSER_TEXT)
               end
             end
           end
         end
       end
     
   end    
 
  #--------------------------------------------------------------------------
  # ● Execute Defeated Sound Effect
  #--------------------------------------------------------------------------              
  def execute_defeated_sound_effect(enemy)
      return if self.battler.no_damage_pop
      Sound.play_enemy_collapse   
  end 
  
  #--------------------------------------------------------------------------
  # ● Execute Final Shoot
  #--------------------------------------------------------------------------             
  def execute_final_shoot(enemy)
      enemy.note  =~ /<Final Action ID = (\d+)>/ 
      action_id = $1.to_i
      return if action_id == nil
      self.shoot(action_id) 
      enemy.note  =~ /<Final Action Per = (\d+) - (\d+)>/ 
      action_id = $1.to_i
      return if action_id == nil
      self.shoot(action_id) if rand(100) < $2.to_i
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute Gain Exp Gold
  #--------------------------------------------------------------------------           
  def execute_gain_exp_gold(enemy)  
      exp = self.battler.exp
      case XAS_BA::EXP_TYPE
         when 0
            actor = $game_party.members[0]
            actor.gain_exp(exp)
         when 1
            for i in 0...$game_party.members.size
               actor = $game_party.members[i]           
               actor.gain_exp(exp)
            end   
         when 2  
            exp = exp / $game_party.members.size 
            for i in 0...$game_party.members.size
               actor = $game_party.members[i]           
               actor.gain_exp(exp)
            end              
      end 
      $game_party.gain_gold(self.battler.gold)
  end  
  
  #--------------------------------------------------------------------------
  # ● Execute_Active Switch
  #--------------------------------------------------------------------------           
  def execute_active_switch(enemy)        
      enemy.note  =~ /<Active Switch = (\d+)>/      
      switch_id = $1.to_i  
      if switch_id != nil
         $game_switches[switch_id] = true
         $game_map.need_refresh = true     
      end
  end
  
  #--------------------------------------------------------------------------
  # ● Execute Defeated Animation
  #--------------------------------------------------------------------------             
  def execute_defeated_animation(enemy)
      enemy.note  =~ /<Defeated Animation = (\d+)>/      
      anime_id = $1.to_i      
      if anime_id != nil
         self.animation_id = anime_id
      end  
  end  
  
end   
 
#===============================================================================
# ■ Game Player
#=============================================================================== 
class Game_Player < Game_Character
  
  #--------------------------------------------------------------------------
  # ● Reset Old Level
  #--------------------------------------------------------------------------             
  def reset_old_level(trans = false)
     for actor in $game_party.members
         actor.old_level = actor.level
     end    
  end
  
  #--------------------------------------------------------------------------
  # ● Change Leader
  #--------------------------------------------------------------------------                  
  def change_leader
      return if $game_party.members.size <= 1
      reset_battler_temp
      current_leader_id = $game_party.members[0].id
      for i in 1..$game_party.members.size 
          pre_leader = $game_party.members[0].id
          $game_party.remove_actor(pre_leader) 
          $game_party.add_actor(pre_leader)  
          if $game_party.members[0].hp > 0
             execute_change_leader_effect unless current_leader_id == $game_party.members[0].id
             break 
          end
      end
  end   
  
  #--------------------------------------------------------------------------
  # ● Exeute Change leader Effect
  #--------------------------------------------------------------------------                    
  def execute_change_leader_effect
      actor = $game_party.members[0] 
      actor.invunerable_duration = XAS_BA::CHANGE_LEADER_WAIT_TIME
      actor.damage = nil
      actor.damage_pop = false
      actor.critical = false
      @knock_back_duration = nil
      if self.action != nil
         self.action.duration = 1
      end
      @force_action_times = 0
      @force_action_type = ""         
      reset_old_level(true)
      @x_pose_original_name = @character_name
      update_battler_pose
      $game_map.need_refresh = true
      self.animation_id = XAS_ANIMATION::CHANGE_LEADER_ANIMATION_ID
      $game_temp.change_leader_wait_time = XAS_BA::CHANGE_LEADER_WAIT_TIME  
  end
  
  #--------------------------------------------------------------------------
  # ● Check Actor Level
  #--------------------------------------------------------------------------           
  def check_actor_level
      return if $game_party.in_battle
      return if self.battler == nil
      return if self.battler.old_level == self.battler.level
      reset_old_level(false)
      if self.battler.level > 1
         Audio.se_play("Audio/SE/" + XAS_SOUND::LEVEL_UP , 100, 100) 
         if XAS_WORD::ENABLE_WORD 
            $game_player.battler.damage = XAS_WORD::LEVEL_UP
            $game_player.battler.damage_pop = true
         end
      end
      $game_player.need_refresh = true
  end 
end   

#===============================================================================
# ■ Game Party
#===============================================================================
class Game_Party < Game_Unit
  
 #--------------------------------------------------------------------------
 # ● Setup Starting Members  
 #--------------------------------------------------------------------------      
  alias x_old_level_setup_starting_members setup_starting_members  
  def setup_starting_members  
      x_old_level_setup_starting_members    
      for actor in $game_party.members
          actor.old_level = actor.level
      end
  end
  
end

#===============================================================================
# ■ Sprite Character
#==============================================================================
class Sprite_Character < Sprite_Base  
  
  #--------------------------------------------------------------------------
  # ● Update Collapse Effects
  #--------------------------------------------------------------------------            
  def update_collaspse_effects
      update_collapse_duration
      return unless can_collapse_effects?
      update_collpase_zoom_effects
      update_exp_gold_pop
  end
    
  #--------------------------------------------------------------------------
  # ● Update Collapse Effects
  #--------------------------------------------------------------------------            
  def update_gain_effects
    if @character.battler.is_a?(Game_Enemy)
      @character.opacity = 0 if @character.battler.gain_duration == 120
      if @character.gain_duration > 0
        @character.opacity += 255 / 120
        @character.battler.gain_duration -= 1
      else
        @character.opacity = 255
      end
    elsif @character.battler.is_a?(Game_Actor)
      @character.opacity = 255
    end
  end
    
  #--------------------------------------------------------------------------
  # ● Can Collapse Effects
  #--------------------------------------------------------------------------              
  def can_collapse_effects?
      return false if @character.battler.is_a?(Game_Actor)
      return true  if @character.battler.no_damage_pop and !@character.erased
      return false unless @character.dead? 
      return false if @character.erased    
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Exp Gold Pop
  #--------------------------------------------------------------------------              
  def update_exp_gold_pop
      return unless XAS_DAMAGE_POP::DAMAGE_EXP_GOLD_POP 
      exp_pop = @character.battler.exp
      gold_pop =@character.battler.gold
      case @character.collapse_duration
           when @character.collapse_duration_save * 275 / 3 / 100
                enemy = $data_enemies[@character.battler.enemy_id]
                @character.make_treasure(enemy)       
           when @character.collapse_duration_save * 2 / 3
             if exp_pop != 0
                word = XAS_WORD::EXP
                totalexp = ($game_party.leader.final_exp_rate * exp_pop).truncate
                @character.battler.damage = word + " +" + totalexp.to_s
                @character.battler.damage_pop = true
                @character.battler.damage_type = "Exp"
             end  
           when @character.collapse_duration_save / 3
             if gold_pop != 0
                word = $data_system.currency_unit
                @character.battler.damage = "+" + gold_pop.to_s + " " + word
                @character.battler.damage_pop = true
                @character.battler.damage_type = "Gold"
             end               
      end      
  end
  
  #--------------------------------------------------------------------------
  # ● Update Collapse Duration
  #--------------------------------------------------------------------------              
  def update_collapse_duration
      @character.collapse_duration -= 1
      if @character.battler.is_a?(Game_Actor)
        @character.opacity -= 0
      else
        @character.opacity -= 2
      end
      if @character.collapse_duration <= 0
         if @character.battler.is_a?(Game_Actor)
            SceneManager.goto(Scene_Gameover)
            return
         end
         self.visible = false
         @character.opacity = 0
         @character.erase
      end  
  end  

  #--------------------------------------------------------------------------
  # ● Update Collapse Zoom Effects
  #--------------------------------------------------------------------------                
  def update_collpase_zoom_effects
      case @character.battler.death_zoom_effect
          when 1
             @character.zoom_y += 0.05
             @character.zoom_x -= 0.01            
          when 2  
             @character.zoom_y -= 0.01
             @character.zoom_x += 0.03             
          when 3  
             @character.zoom_y += 0.03
             @character.zoom_x += 0.03              
          when 4   
             @character.zoom_y -= 0.005
             @character.zoom_x -= 0.005
          when 5   
            case @character.collapse_duration
                when 60..120
                 @character.zoom_y -= 0.01
                 @character.zoom_x += 0.06                             
                when 0..59  
                 @character.zoom_y += 0.2
                 @character.zoom_x -= 0.1 
             end
          when 6
             @character.zoom_y = 0
             @character.zoom_x = 0            
          when 7
            case @character.collapse_duration
                when 0..29
                 @character.zoom_y += 0.01
                 @character.zoom_x += 0.01
                when 30..59
                 @character.zoom_y -= 0.05
                 @character.zoom_x -= 0.05
                when 60..89
                 @character.zoom_y += 0.3
                 @character.zoom_x += 0.3
                when 90..120
                 @character.zoom_y -= 0.3
                 @character.zoom_x -= 0.3
              end
             
      end
  end  
  
end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ BATTLER - TREASURE
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ XAS_BA_Item_Drop
#==============================================================================
module XAS_BA_ItemDrop
  
  #--------------------------------------------------------------------------
  # ● Defeat Process
  #--------------------------------------------------------------------------               
  def make_treasure(enemy)  
      treasure = nil      
      treasure_xy = nil      
      treasure_r = nil      
      dif = []
      i=3
      for drop in enemy.extra_drops
           next if !$game_switches[drop.switch]
           next if drop.kind == 0
           if drop.drop_rate_size <= 0
             next if rand(100) >= drop.drop_rate
           else
             next if rand(100 * ( 10 ** drop.drop_rate_size )) > drop.drop_rate * ( 10 ** drop.drop_rate_size )
           end
           if drop.kind == 1
              treasure = $data_items[drop.data_id]
              tr_id = treasure.id
           elsif drop.kind == 2
              treasure = $data_weapons[drop.data_id]
              tr_id = treasure.id
           elsif drop.kind == 3
              treasure = $data_armors[drop.data_id]
              tr_id = treasure.id
           end
       if treasure != nil
          command = RPG::MoveCommand.new
          command.code = 14
          command.parameters = [0,0]
          route = RPG::MoveRoute.new
          route.repeat = false
          route.list = [command, RPG::MoveCommand.new]         
          page = RPG::Event::Page.new
          page.move_type = 3
          page.move_route = route
          page.move_frequency = 6
          page.priority_type = 1
          page.trigger = 1
          page.through = true
          xx = rand(i) - (i-1)/2
          yy = rand(i) - (i-1)/2
          while dif.size >= i**2
            i+=2
          end
          while dif.include?([xx, yy]) and dif.size >= (i-2)**2 and  dif.size < i**2
            xx = rand(i) - (i-1)/2
            yy = rand(i) - (i-1)/2
          end
          dif.push([xx, yy])
          event = RPG::Event.new(self.x, self.y)
          event.pages = [page]       
          event = RPG::Event.new(self.x, self.y)
          token = Token_Event.new($game_map.map_id, event)
          token.icon_name = treasure.icon_index
          token.treasure = [drop.kind,tr_id]
          token.treasure_time = 120 + XAS_BA::TREASURE_ERASE_TIME * 60
          token.jump_high(xx,yy,5)
          token.force_update = true
          token.move_speed = 6
          $game_map.add_token(token)
       end  
      end
#-------------------------------------------------------------------------------
      for drop_xy in enemy.extra_drops_xy
           next if !$game_switches[drop_xy.switch]
           next if drop_xy.kind == 0
           if drop_xy.drop_rate_size <= 0
             next if rand(100) > drop_xy.drop_rate
           else
             next if rand(100 * ( 10 ** drop_xy.drop_rate_size )) > drop_xy.drop_rate * ( 10 ** drop_xy.drop_rate_size )
           end
           if drop_xy.kind == 1
              treasure_xy = $data_items[drop_xy.data_id]
              tr_id_xy = treasure_xy.id
           elsif drop_xy.kind == 2
              treasure_xy = $data_weapons[drop_xy.data_id]
              tr_id_xy = treasure_xy.id
           elsif drop_xy.kind == 3
              treasure_xy = $data_armors[drop_xy.data_id]
              tr_id_xy = treasure_xy.id
           end
       if treasure_xy != nil
          command = RPG::MoveCommand.new
          command.code = 14
          command.parameters = [0,0]
          route = RPG::MoveRoute.new
          route.repeat = false
          route.list = [command, RPG::MoveCommand.new]         
          page = RPG::Event::Page.new
          page.move_type = 3
          page.move_route = route
          page.move_frequency = 6
          page.priority_type = 1
          page.trigger = 1
          page.through = true
          event = RPG::Event.new(self.x, self.y)
          event.pages = [page]       
          event = RPG::Event.new(self.x, self.y)
          token = Token_Event.new($game_map.map_id, event)
          token.icon_name = treasure_xy.icon_index
          token.treasure = [drop_xy.kind,tr_id_xy]
          token.treasure_time = 120 + XAS_BA::TREASURE_ERASE_TIME * 60
          token.jump_high(drop_xy.px,drop_xy.py,5)
          token.force_update = true
          token.move_speed = 6
          $game_map.add_token(token)
       end  
      end
#-------------------------------------------------------------------------------
      for drop_r in enemy.extra_drops_r
           next if !$game_switches[drop_r.switch]
           next if drop_r.kind == 0
           if drop_r.drop_rate_size <= 0
             next if rand(100) > drop_r.drop_rate
           else
             next if rand(100 * ( 10 ** drop_r.drop_rate_size )) > drop_r.drop_rate * ( 10 ** drop_r.drop_rate_size )
           end
           if drop_r.kind == 1
              treasure_r = $data_items[drop_r.data_id]
              tr_id_r = treasure_r.id
           elsif drop_r.kind == 2
              treasure_r = $data_weapons[drop_r.data_id]
              tr_id_r = treasure_r.id
           elsif drop_r.kind == 3
              treasure_r = $data_armors[drop_r.data_id]
              tr_id_r = treasure_r.id
           end
           break if treasure_r != nil 
       end   
#~        if treasure != nil #&& rand(100) < drop.drop_rate
#~           command = RPG::MoveCommand.new
#~           command.code = 14
#~           command.parameters = [0,0]
#~           route = RPG::MoveRoute.new
#~           route.repeat = false
#~           route.list = [command, RPG::MoveCommand.new]         
#~           page = RPG::Event::Page.new
#~           page.move_type = 3
#~           page.move_route = route
#~           page.move_frequency = 6
#~           page.priority_type = 1
#~           page.trigger = 1
#~           page.through = true
#~           event = RPG::Event.new(self.x, self.y)
#~           event.pages = [page]       
#~           event = RPG::Event.new(self.x, self.y)
#~           token = Token_Event.new($game_map.map_id, event)
#~           token.icon_name = treasure.icon_index
#~           token.treasure = [drop.kind,tr_id]
#~           token.treasure_time = 120 + XAS_BA::TREASURE_ERASE_TIME * 60
#~           token.jump_high(0,0,rand(11)+15)
#~           token.force_update = true
#~           token.move_speed = 6
#~           $game_map.add_token(token)
#~        end  
#~        if treasure1 != nil #&& rand(100) < drop1.drop_rate
#~           command = RPG::MoveCommand.new
#~           command.code = 14
#~           command.parameters = [0,0]
#~           route = RPG::MoveRoute.new
#~           route.repeat = false
#~           route.list = [command, RPG::MoveCommand.new]         
#~           page = RPG::Event::Page.new
#~           page.move_type = 3
#~           page.move_route = route
#~           page.move_frequency = 6
#~           page.priority_type = 1
#~           page.trigger = 1
#~           page.through = true
#~           event = RPG::Event.new(self.x - 1, self.y)
#~           event.pages = [page]       
#~           event = RPG::Event.new(self.x - 1, self.y)
#~           token = Token_Event.new($game_map.map_id, event)
#~           token.icon_name = treasure1.icon_index
#~           token.treasure = [drop1.kind,tr_id1]
#~           token.treasure_time = 120 + XAS_BA::TREASURE_ERASE_TIME * 60
#~           token.jump_high(0,0,rand(11)+15)
#~           token.force_update = true
#~           token.move_speed = 6
#~           $game_map.add_token(token)
#~        end  
       if treasure_r != nil #&& rand(100) < dropR.drop_rate
          command = RPG::MoveCommand.new
          command.code = 14
          command.parameters = [0,0]
          route = RPG::MoveRoute.new
          route.repeat = false
          route.list = [command, RPG::MoveCommand.new]         
          page = RPG::Event::Page.new
          page.move_type = 3
          page.move_route = route
          page.move_frequency = 6
          page.priority_type = 1
          page.trigger = 1
          page.through = true
          event = RPG::Event.new(self.x + ( rand(2) - 1 ), self.y + ( rand(2) - 1 ))
          event.pages = [page]       
          event = RPG::Event.new(self.x + ( rand(2) - 1 ), self.y + ( rand(2) - 1 ))
          token = Token_Event.new($game_map.map_id, event)
          token.icon_name = treasure_r.icon_index
          token.treasure = [drop_r.kind,tr_id_r]
          token.treasure_time = 120 + XAS_BA::TREASURE_ERASE_TIME * 60
          token.jump_high(0,0,rand(11)+15)
          token.force_update = true
          token.move_speed = 6
          $game_map.add_token(token)
       end  
  end  
  
  #--------------------------------------------------------------------------
  # ● ドロップアイテム取得率の倍率を取得
  #--------------------------------------------------------------------------
  def drop_item_rate
    $game_party.drop_item_double? ? 2 : 1
  end

end

#===============================================================================
# ■ Game Event
#===============================================================================
class Game_Event < Game_Character
  include XAS_BA_ItemDrop
  
  #--------------------------------------------------------------------------
  # ● Update Treasure Duration
  #--------------------------------------------------------------------------               
  def update_treasure_duration
      return if @treasure_time == 0
      @treasure_time -= 1
      self.erase if @treasure_time == 0
  end
  
end

#===============================================================================
# ■ Game Character
#==============================================================================
class Game_Character < Game_CharacterBase
  attr_accessor :icon_name
  attr_accessor :treasure
end

#===============================================================================
# ■ Game Character
#==============================================================================
class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------             
  alias xrxs_charactericon_update update
  def update
      xrxs_charactericon_update
      if @character.icon_name != nil 
         self.bitmap = Cache.system("Iconset")
         self.src_rect.set(@character.icon_name  % 16 * 24, @character.icon_name / 16 * 24, 24, 24)
         self.ox = 12
         self.oy = 24
      end
  end
end

#===============================================================================
# ■ Game Player
#==============================================================================
class Game_Player < Game_Character
  
  #--------------------------------------------------------------------------
  # ● Check Event Trigger Here
  #--------------------------------------------------------------------------               
  alias treasure_check_event_trigger_here check_event_trigger_here
  def check_event_trigger_here(triggers)
      return false if $game_map.interpreter.running?
      check_treasure_here         
      treasure_check_event_trigger_here(triggers)
  end  
 
  #--------------------------------------------------------------------------
  # ● check_treasure_here   
  #--------------------------------------------------------------------------                 
  def check_treasure_here   
     for event in $game_map.events_xy(@x, @y)
         if event.treasure != nil 
            name_pop = true
            case event.treasure[0]            
            when 1
                  item = $data_items[event.treasure[1]]
                  if can_execute_field_item_effect?(item)
                     name_pop = false
                  else  
                     $game_party.gain_item(item, 1)
                  end
                  $game_map.need_refresh = true
            when 2  
                  item = $data_weapons[event.treasure[1]]
                  $game_party.gain_item($data_weapons[event.treasure[1]], 1,false)
            when 3
                  item = $data_armors[event.treasure[1]]
                  $game_party.gain_item(item, 1,false)
            end
            Audio.se_play("Audio/SE/" + XAS_SOUND::ITEM_DROP , 100, 100)   
            event.erase
            if item != nil
                if item.note =~ /<Drop Ani = (\d+)>/
                   self.animation_id = $1.to_i
                end
                if XAS_DAMAGE_POP::DAMAGE_ITEM_POP and name_pop
                   self.battler.damage = item.name.to_s
                   self.battler.damage_pop = true
                   self.battler.damage_type = "Item"
                end                       
            end
            if item.note =~ /<Drop Gold = (\d+)>/
            SceneManager.scene.event_window_add_text(YEA::EVENT_WINDOW::HEADER_TEXT+"\ec[24]획득\ec[0] : \ec[17]"+$1.to_i.to_s+"\ec[0] \ei[751]"+YEA::EVENT_WINDOW::CLOSER_TEXT)
            else
            SceneManager.scene.event_window_add_text(YEA::EVENT_WINDOW::HEADER_TEXT+"\ec[24]획득\ec[0] : "+"\ei[#{item.icon_index}] \ec[24]"+item.name+YEA::EVENT_WINDOW::CLOSER_TEXT)
          end
          
            $game_system.quest.ids.each do |id|
              data = $game_system.quest[id]
              next unless data.visible
              if data.playing #and !data.quest_clear? and !data.alarm
                for i in 0...data.condition.size
                  if data.condition[i].type == event.treasure[0] - 1 and data.condition[i].id == item.id
                      $game_temp.event_window_data2 = [] if $game_temp.event_window_data2.nil?
                      $game_temp.event_window_data2.each do |i|
                        $game_temp.event_window_data2.delete(i) if i.include?("\ec[27]#{data.name}\ec[0] : \ei[#{item.icon_index}]") or !i.include?("\ec[18]")
                      end
                    if $game_party.item_number(item) == data.condition[i].num
                      SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[24]#{data.name}\ec[0] : \ei[#{item.icon_index}] \ec[24]#{$game_party.item_number(item)}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]    "+YEA::EVENT_WINDOW2::CLOSER_TEXT)
                      Audio.se_play("Audio/SE/Chime2", 100, 100) if $game_party.item_number(item) == data.condition[i].num
                    elsif $game_party.item_number(item) < data.condition[i].num
                      SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[27]#{data.name}\ec[0] : \ei[#{item.icon_index}] \ec[18]#{$game_party.item_number(item)}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]    "+YEA::EVENT_WINDOW2::CLOSER_TEXT)
                    end
                  elsif data.condition[i].type == 3 and item.note =~ /<Drop Gold = (\d+)>/
                      $game_temp.event_window_data2 = [] if $game_temp.event_window_data2.nil?
                      $game_temp.event_window_data2.each do |i|
                        $game_temp.event_window_data2.delete(i) if i.include?("\ec[27]#{data.name}\ec[0] : \ei[751]") or !i.include?("\ec[18]")
                      end
                    if $game_party.gold == data.condition[i].num
                      SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[24]#{data.name}\ec[0] : \ei[751] \ec[24]#{$game_party.gold}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]    "+YEA::EVENT_WINDOW2::CLOSER_TEXT)
                      Audio.se_play("Audio/SE/Chime2", 100, 100) if $game_party.gold == data.condition[i].num
                    elsif $game_party.gold < data.condition[i].num
                      SceneManager.scene.event_window_add_text2(YEA::EVENT_WINDOW2::HEADER_TEXT+"\ec[27]#{data.name}\ec[0] : \ei[751] \ec[18]#{$game_party.gold}\ec[0] / \ec[24]#{data.condition[i].num.to_s}\ec[0]    "+YEA::EVENT_WINDOW2::CLOSER_TEXT)
                    end
                  end
                end
              end
            end
          
          end   
     end   
 end           
     
  #--------------------------------------------------------------------------
  # ● Can Execute Field Item Effect
  #--------------------------------------------------------------------------                  
  def can_execute_field_item_effect?(item)
      if item.note =~ /<Drop HP Damage = (\S+)>/
         damage = $1.to_i
         damage2 = damage #* self.battler.mhp / 100
         self.battler.damage = damage2
         self.battler.damage_pop = true
         self.battler.hp -= damage2
         if self.battler.hp < ( self.battler.mhp * XAS_BA_ENEMY::LOWHP / 100 ) && ( damage2 > 0 )
           $game_map.screen.start_flash(Color.new(255, 0, 0), 8)
         else
           $game_map.screen.start_flash(Color.new(255, 0, 0, 50), 8)
         end
         return true
      end  
      if item.note =~ /<Drop MP Damage = (\S+)>/
         damage = $1.to_i
         damage2 = damage #* self.battler.mmp / 100
         self.battler.mp -= damage2         
         self.battler.damage_type = "Mp"   
         self.battler.damage = damage2
         self.battler.damage_pop = true
         return true
      end       
      if item.note =~ /<Drop Gold = (\d+)>/
         gold = $1.to_i
         damage = $data_system.currency_unit
         self.battler.damage = "+" + gold.to_s + " " + damage
         self.battler.damage_pop = true
         self.battler.damage_type = "Gold"
         $game_party.gain_gold(gold)
         return true
      end
      return false  
  end  
end 



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ SPRITE - POSE (Character Name)
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■ Game_Character
#===============================================================================
class Game_Character < Game_CharacterBase
  
  attr_accessor :x_pose_duration
  attr_accessor :x_pose_name
  attr_accessor :x_pose_original_name
  attr_accessor :character_name
  
  #-----------------------------------------------------------------------------
  # ● Initialize
  #-----------------------------------------------------------------------------  
  alias x_pose_initialize initialize
  def initialize
      x_pose_initialize
      @x_pose_duration = 0
      @x_pose_name = ""
      @x_pose_original_name = @character_name
  end

  #-----------------------------------------------------------------------------
  # ● Update
  #-----------------------------------------------------------------------------    
  def make_pose(sufix, pose_duration)
      return if @x_pose_original_name == ""
      @x_pose_name = sufix
      @x_pose_duration = pose_duration         
  end     
  
  #-----------------------------------------------------------------------------
  # ● Update Pose
  #-----------------------------------------------------------------------------    
  def update_battler_pose
      return false unless XAS_SYSTEM::CHARACTER_POSE_NAME
      if @x_pose_duration == 0
         @x_pose_original_name = @character_name
         return
      else     
         @x_pose_duration -= 1
         @character_name = @x_pose_original_name + @x_pose_name
         if @x_pose_duration == 0
            @character_name = @x_pose_original_name
            @x_pose_name = ""
         end
      end
      unless jumping? 
         @jump_count = 0
         @jump_peak = 0
      end       
  end
  
  #-----------------------------------------------------------------------------
  # ● Set Graphic
  #-----------------------------------------------------------------------------      
  alias x_pose_set_graphic set_graphic
  def set_graphic(character_name, character_index)
      x_pose_set_graphic(character_name, character_index)
      @x_pose_original_name = @character_name
      @x_pose_duration = 0
      @x_pose_name = ""      
  end    
  
end


#===============================================================================
# ■ Game_Interpreter
#===============================================================================
class Game_Interpreter
  
  #-----------------------------------------------------------------------------
  # ● Command_322
  #-----------------------------------------------------------------------------    
  alias x_pose_command_322 command_322
  def command_322
      x_pose_command_322
      actor = $game_actors[@params[0]]
      if actor != nil
         $game_player.x_pose_duration = 0
         $game_player.x_pose_original_name =  @params[1]
      end
  end
  
end  

#===============================================================================
# ■ RPG_FileTest 
#===============================================================================
module RPG_FileTest
  
  #--------------------------------------------------------------------------
  # ● RPG_FileTest.character_exist?
  #--------------------------------------------------------------------------
  def RPG_FileTest.character_exist?(filename)
      return Cache.character(filename) rescue return false
  end

  #--------------------------------------------------------------------------
  # ● RPG_FileTest.system_exist?
  #--------------------------------------------------------------------------
  def RPG_FileTest.system_exist?(filename)
      return Cache.system(filename) rescue return false
  end  
  
end

#===============================================================================
# ■ Sprite_Character
#===============================================================================
class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # ● X Pose Update
  #--------------------------------------------------------------------------  
  alias x_pose_update_bitmap update_bitmap
  def update_bitmap
      check_file_exist
      x_pose_update_bitmap
  end
 
 #--------------------------------------------------------------------------
 # ● Check File Exist
 #--------------------------------------------------------------------------  
 def check_file_exist
     return if @character_name == @character.character_name
     unless RPG_FileTest.character_exist?(@character.character_name)
            @character.character_name = @character.x_pose_original_name    
            @character.x_pose_duration = 0
            @character.x_pose_name = ""
     end         
 end  
  
end





#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ SPRITE - DAMAGE SPRITE
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#===============================================================================
# ■  XRXS_DAMAGE_OFFSET
#===============================================================================
module XRXS_DAMAGE_OFFSET
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------              
  def update
      super
      @damage_sprites   = [] if @damage_sprites.nil?
      for damage_sprite in @damage_sprites
          damage_sprite.x = self.x
          damage_sprite.y = self.y
      end
  end
end

#===============================================================================
# ■ Sprite_Character
#===============================================================================
class Sprite_Character < Sprite_Base
      include XRXS_DAMAGE_OFFSET
end


#==============================================================================
# ■ Sprite Base
#==============================================================================
class Sprite_Base < Sprite
  include XAS_DAMAGE_POP
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------   
  alias x_damage_pop_initialize initialize
  def initialize(viewport = nil)      
      @_damage_duration = 0
      x_damage_pop_initialize(viewport) 
  end
  
  #--------------------------------------------------------------------------
  # ● Damage
  #--------------------------------------------------------------------------     
  def damage(value, type = "")
      dispose_damage
      @damage_ox = 0
      @damage_type = type
      # NUMBER PICTURE
      if value.is_a?(Numeric) 
         bitmap_number_image = Cache.system("XAS_Damage_Number")
         bitmap_im_cw = bitmap_number_image.width / 10
         bitmap_im_ch = bitmap_number_image.height / 5            
         bitmap = Bitmap.new(bitmap_number_image.width * 3,(bitmap_im_ch * 2) + 5)
         bitmap_number_text = value.to_s.split(//)
         center_x = (((2 + bitmap_number_text.size) * bitmap_im_cw) / 2)
         # Damage Color         
         if value >= 0
            if @damage_type == "Critical"
               h = bitmap_im_ch * 2  
               h2 = bitmap_im_ch * 4
               $game_map.screen.start_shake(5, 5, 60)
            elsif @damage_type == "Mp"   
               h = bitmap_im_ch * 0  
               h2 = bitmap_im_ch * 3
            else
               h = 0
            end
            f = 0
          else # Recover Color   
            h = bitmap_im_ch  
            h2 = bitmap_im_ch * 3 if @damage_type == "Mp"     
            f = 1
        end   
        for r in f..bitmap_number_text.size - 1
            bitmap_number_abs = bitmap_number_text[r].to_i
            bitmap_src_rect = Rect.new(bitmap_im_cw * bitmap_number_abs, h, bitmap_im_cw, bitmap_im_ch)
            bitmap.blt(center_x + (bitmap_im_cw  *  r), bitmap_im_ch + 5, bitmap_number_image, bitmap_src_rect)                  
        end 
        ex = (bitmap_im_cw / 2) * (bitmap_number_text.size + f)
        @damage_ox = (bitmap_number_image.width - (bitmap_number_image.width / 2) - ex) - center_x 
        # Add Extra String (MP / Critical)
        if h2 != nil
           string_x = (center_x - (bitmap_number_image.width / 2) + (bitmap_im_cw / 2) * bitmap_number_text.size)
           bitmap_src_rect = Rect.new(0, h2,  bitmap_number_image.width, bitmap_im_ch)
           bitmap.blt(string_x , 0, bitmap_number_image, bitmap_src_rect)   
        end        
        bitmap_number_image.dispose  
      else 
          #TEXT STRING
          damage_string = value.to_s
          bitmap = Bitmap.new(160, 48)
          bitmap.font.name = DAMAGE_FONT_NAME
          bitmap.font.size = DAMAGE_FONT_SIZE
          bitmap.font.bold = DAMAGE_FONT_BOLD
          bitmap.font.italic = DAMAGE_FONT_ITALIC
          bitmap.font.color = Color.new(0,0,0)
          bitmap.draw_text(0, 12, 160, 36, damage_string, 1)
          case @damage_type
               when "Exp";   string_color = DAMAGE_EXP_FONT_COLOR
               when "Gold";  string_color = DAMAGE_GOLD_FONT_COLOR
               when "Item";  string_color = DAMAGE_ITEM_FONT_COLOR
          else
             string_color = DAMAGE_DEFAULT_FONT_COLOR
          end
          bitmap.font.color = string_color
          bitmap.draw_text(0, 12, 160, 36, damage_string, 1)              
      end 
       @_damage_sprite = ::Sprite.new(self.viewport)
       @_damage_sprite.bitmap = bitmap
       @_damage_sprite.ox = 80
       @_damage_sprite.oy = 20
       @_damage_sprite.x = self.x + @damage_ox
       @_damage_sprite.y = self.y - self.oy / 2
       @_damage_sprite.z = 3000
       @_damage_duration = 60
   end

  #--------------------------------------------------------------------------
  # ● Dispose Damage
  #--------------------------------------------------------------------------       
  def dispose_damage
      if @_damage_sprite != nil
         @_damage_sprite.bitmap.dispose
         @_damage_sprite.dispose
         @_damage_sprite = nil
         @_damage_duration = 0
      end
  end
  
  #--------------------------------------------------------------------------
  # ● Dispose
  #--------------------------------------------------------------------------         
  alias x_damage_dispose dispose
  def dispose 
      dispose_damage
      x_damage_dispose
  end
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------           
  alias x_damage_pop_update update
  def update
      if @_damage_duration > 0
         @_damage_duration -= 1
         if @_damage_duration == 0
            dispose_damage
         end
       end      
       x_damage_pop_update
  end    
    
end  

#===============================================================================
# ■ XRXS DAMAGE
#===============================================================================
module XRXS_DAMAGE
  
  #--------------------------------------------------------------------------
  # ● Damage X Init Velocity
  #--------------------------------------------------------------------------                             
  def damage_x_init_velocity
      return 0.2 * (rand(5) - 2) 
  end
    
  #--------------------------------------------------------------------------
  # ● Damage Y Init Velocity
  #--------------------------------------------------------------------------                             
  def damage_y_init_velocity
      return 9
  end
    
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------                               
  def update
    super
    @damage_sprites   = [] if @damage_sprites.nil?
    @damage_durations = [] if @damage_durations.nil?
    if @_damage_sprite != nil and @_damage_sprite.visible
       if @damage_ox != nil
          dam_ox = @damage_ox
       else   
          dam_ox = 0
       end        
       if @damage_type != nil
          dam_type = @damage_type
       end  
       x = damage_x_init_velocity
       y = damage_y_init_velocity
       d = @_damage_duration
       @damage_sprites.push(Sprite_Damage.new(@_damage_sprite, x, y, d,dam_ox,dam_type))
       @_damage_sprite.visible = false
    end
    for damage_sprite in @damage_sprites
        damage_sprite.update
    end
    for i in 0...@damage_sprites.size
        @damage_sprites[i] = nil if @damage_sprites[i].disposed?
    end
    @damage_sprites.compact!
  end
  def dispose
    super
    if @damage_sprites != nil
       for damage_sprite in @damage_sprites
           damage_sprite.dispose
       end
     end
  end
end

#===============================================================================
# ■ RPG Sprite
#===============================================================================
class Sprite_Base < Sprite
      include XRXS_DAMAGE
end

#===============================================================================
# ■ Sprite Damage
#===============================================================================
class Sprite_Damage < Sprite
  
  #--------------------------------------------------------------------------
  # ● Initialize
  #--------------------------------------------------------------------------                        
  def initialize(sprite, init_x_speed, init_y_speed, duration,dam_ox,dam_type = nil)
      super(nil)
      self.bitmap = sprite.bitmap.dup unless sprite.bitmap.nil?
      self.opacity = sprite.opacity
      self.x = sprite.x
      self.y = sprite.y
      self.z = sprite.z
      self.ox = sprite.ox - dam_ox
      self.oy = sprite.oy
      @now_x_speed = init_x_speed
      @now_y_speed = init_y_speed
      @potential_x_energy = 0.0
      @potential_y_energy = 0.0
      @duration = duration
      @dam_type = dam_type
      @dam_type = "" if dam_type == nil
  end

  #--------------------------------------------------------------------------
  # ● Update    
  #--------------------------------------------------------------------------                       
  def update
    super
    if XAS_DAMAGE_POP::DAMAGE_CRITICAL_ZOOM
       if @dam_type != "Critical"
          update_normal_popup
       else  
          update_critical_effect   
       end      
    else      
       update_normal_popup
    end
    @duration -= 1
    if @duration == 0
       self.dispose
    end
  end
  
  #--------------------------------------------------------------------------
  # ● update_critical_effect
  #--------------------------------------------------------------------------                           
  def update_critical_effect  
      case @duration
         when 40..60
           self.zoom_x += 0.1
           self.zoom_y += 0.1
         else   
           if self.zoom_x > 0.1   
              self.zoom_x -= 0.1
              self.zoom_y -= 0.1
           end
       end
  end
  
  #--------------------------------------------------------------------------
  # ● update_normal_popup
  #--------------------------------------------------------------------------                         
  def update_normal_popup
      self.opacity -= 25 if @duration <= 10
      n = self.oy + @now_y_speed
      if n <= 0
         @now_y_speed *= -1
         @now_y_speed /=  2
         @now_x_speed /=  2
      end
      self.oy  = [n, 0].max    
      @potential_y_energy += 0.58
      speed = @potential_y_energy.floor
      @now_y_speed        -= speed
      @potential_y_energy -= speed
      @potential_x_energy += @now_x_speed
      speed = @potential_x_energy.floor
      self.ox             += speed
      @potential_x_energy -= speed  
    end
 
end



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ SPRITE - SPRITE EFFECTS
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#==============================================================================
# ■ Sprite Base 
#==============================================================================
class Sprite_Base < Sprite  

  #--------------------------------------------------------------------------
  # ● Animation Set Sprite
  #--------------------------------------------------------------------------
  def animation_set_sprites(frame)
      cell_data = frame.cell_data
      @ani_sprites.each_with_index do |sprite, i|
        next unless sprite
        pattern = cell_data[i, 0]
        if !pattern || pattern < 0
            sprite.visible = false
            next
        end
        sprite.bitmap = pattern < 100 ? @ani_bitmap1 : @ani_bitmap2
        sprite.visible = true
        sprite.src_rect.set(pattern % 5 * 192,
        pattern % 100 / 5 * 192, 192, 192)
        if @ani_mirror
           cx = cell_data[i, 1]
           sprite.angle = (360 - cell_data[i, 4])
           sprite.mirror = (cell_data[i, 5] == 0)
        else
           cx = cell_data[i, 1]
           sprite.angle = cell_data[i, 4]
           sprite.mirror = (cell_data[i, 5] == 1)
        end
        cy = cell_data[i, 2]
        sprite.z = self.z + 300 + i
        sprite.ox = 96
        sprite.oy = 96
        sprite.zoom_x = cell_data[i, 3] / 100.0
        sprite.zoom_y = cell_data[i, 3] / 100.0
        sprite.opacity = cell_data[i, 6] * self.opacity / 255.0
        sprite.blend_type = cell_data[i, 7]
        case @animation.position 
              when 0
                  sprite.x = self.x + cx
                  sprite.y = self.y + cy - (height / 2)          
              when 1
                  sprite.x = self.x + cx
                  sprite.y = self.y + cy         
              when 2
                  sprite.x = self.x + cx
                  sprite.y = self.y + cy + (height / 2) 
              when 3  
                  sprite.x  = (640 / 2) + cx
                  sprite.y  = (480 / 2) + cy     
        end        
        
        
    end
  end  
  
  #--------------------------------------------------------------------------
  # ● Dispose Animation
  #--------------------------------------------------------------------------
  def dispose_animation
      $game_temp.animation_garbage = [] if $game_temp.animation_garbage == nil
      if @ani_bitmap1
         @@_reference_count[@ani_bitmap1] -= 1
        if @@_reference_count[@ani_bitmap1] == 0
            $game_temp.animation_garbage.push(@ani_bitmap1)
         end
      end
      if @ani_bitmap2
         @@_reference_count[@ani_bitmap2] -= 1
         if @@_reference_count[@ani_bitmap2] == 0
            $game_temp.animation_garbage.push(@ani_bitmap2)
        end
     end
     if @ani_sprites
        @ani_sprites.each {|sprite| sprite.dispose }
        @ani_sprites = nil
        @animation = nil
     end
     @ani_bitmap1 = nil
     @ani_bitmap2 = nil
  end    
  
end

#==============================================================================
# ■ Scene_Base
#==============================================================================
class Game_Map
    
  #--------------------------------------------------------------------------
  # ● Setup
  #--------------------------------------------------------------------------    
  alias animation_garbage_setup setup
  def setup(map_id)
      animation_garbage_setup(map_id)
      dispose_animation_garbage
  end
  
  #--------------------------------------------------------------------------
  # ● Dispose Animation Garbage
  #--------------------------------------------------------------------------  
  def dispose_animation_garbage
      return if $game_temp.animation_garbage == nil
      for animation in $game_temp.animation_garbage
          animation.dispose 
      end  
      $game_temp.animation_garbage = nil
  end  
  
end  

#==============================================================================
# ■ Scene_Base
#==============================================================================
class Scene_Base
  
  #--------------------------------------------------------------------------
  # ● Scene Changing?
  #--------------------------------------------------------------------------    
  alias animation_garbage_scene_changing scene_changing? 
  def scene_changing?
      $game_map.dispose_animation_garbage if SceneManager.scene != self
      animation_garbage_scene_changing
  end

end  

#===============================================================================
# ■ Sprite_Character
#===============================================================================
class Sprite_Character < Sprite_Base
  include XAS_SYSTEM
  
  #--------------------------------------------------------------------------
  # ● Setup New Effect
  #--------------------------------------------------------------------------              
  def setup_new_effect
      if @character.animation_id > 0
         animation = $data_animations[@character.animation_id]
         start_animation(animation)
         @character.animation_id = 0
      end
      if !@balloon_sprite && @character.balloon_id > 0
         @balloon_id = @character.balloon_id
         start_balloon
      end
  end  
  
  #--------------------------------------------------------------------------
  # ● Can Update X Effects
  #--------------------------------------------------------------------------                    
  def can_update_x_effects?
      return false unless CHARACTER_SPRITE_EFFECTS
      return false if @character.erased
      return false if @character.transparent == true
      return true
  end  
  #--------------------------------------------------------------------------
  # ● Can Damage Pop Base
  #--------------------------------------------------------------------------                  
  def can_damage_pop_base?
      return false unless $game_system.xas_battle
      return false if XAS_SYSTEM::DAMAGE_POP == false 
      return false if @character.battler == nil
      return false if @character.battler.no_damage_pop  
      return false if @character.battler.damage_pop != true
      return true  
  end  
  
  
  #--------------------------------------------------------------------------
  # ● Execute Damage Pop
  #--------------------------------------------------------------------------              
  def execute_damage_pop  
      damage(@character.battler.damage, @character.battler.damage_type)
      @character.battler.damage = nil
      @character.battler.critical = false
      @character.battler.damage_pop = false
      @character.battler.damage_type = ""
  end
    
  #--------------------------------------------------------------------------
  # ● Update X Effects
  #--------------------------------------------------------------------------              
  def update_x_effects
      update_collaspse_effects if @character.collapse_duration > 0
      if @character.gain_duration != nil
      update_gain_effects if @character.gain_duration > 0
      end
      update_sprite_position
      update_angle
      update_zoom
  end
    
  #--------------------------------------------------------------------------
  # ● Update Angle
  #--------------------------------------------------------------------------          
  def update_angle
      return if @character.angle == self.angle
      self.angle = @character.angle
  end
  
  #--------------------------------------------------------------------------
  # ● Update Zoom 
  #--------------------------------------------------------------------------            
  def update_zoom
      update_treasure_effect
      update_breath_effect if can_breath_effect?
      self.zoom_x = @character.zoom_x
      self.zoom_y = @character.zoom_y
  end
  
  #--------------------------------------------------------------------------
  # ● Update Treasure_effect
  #--------------------------------------------------------------------------                      
  def update_treasure_effect
      return if @character.treasure_time == 0
      update_treasure_fade_effect
      update_treasure_float_effect
  end  
  
  #--------------------------------------------------------------------------
  # ● update_treasure_fade_effect
  #--------------------------------------------------------------------------                        
  def update_treasure_fade_effect
      return unless XAS_BA::FADE_TREASURE_SPRITE 
      return if @character.treasure_time > 100
      return if @character.zoom_x < 0.01      
      @character.zoom_x -= 0.01
      if @character.temp_id > 0
         @character.zoom_x = 1.00
         @character.treasure_time = 120 + XAS_BA::TREASURE_ERASE_TIME * 60
      end
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Treasure Float Effect
  #--------------------------------------------------------------------------                          
  def update_treasure_float_effect
      return unless XAS_BA::FLOAT_TREASURE_SPRITE    
      return if self.character.jumping?
      self.character.treasure_float[2] += 1
      if self.character.treasure_float[2] > 1
         self.character.treasure_float[2] = 0
         self.character.treasure_float[1] += 1
         case self.character.treasure_float[1]
            when 1..15 
              self.character.treasure_float[0] -= 1
            when 16..30
              self.character.treasure_float[0] += 1
            else
              self.character.treasure_float[0] = 0
              self.character.treasure_float[1] = 0 
          end 
      end   
      self.y +=  self.character.treasure_float[0]
  end
  
  #--------------------------------------------------------------------------
  # ● Can Breath Effect?
  #--------------------------------------------------------------------------                    
  def can_breath_effect?
      return false if @character.battler == nil
      return false if @character.battler.breath_effect == false
      return false if @character.battler.hp == 0
      return false if @character.stop and not @character.battler.state_sleep
      return true
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Breath Effect
  #--------------------------------------------------------------------------                  
  def update_breath_effect 
      if @character.battler.fast_breath_effect
          zoom_speed = 3
          zoom_power_x = 0.006    
          zoom_power_y = 0.006        
      else
          zoom_speed = 1
          zoom_power_x = 0    
          zoom_power_y = 0.002
      end
      @character.battler.breath_duration += zoom_speed 
      case @character.battler.breath_duration 
           when 1..30
                @character.zoom_x += zoom_power_x
                @character.zoom_y += zoom_power_y
           when 31..60
                @character.zoom_x -= zoom_power_x
                @character.zoom_y -= zoom_power_y
           else  
                @character.battler.breath_duration = 0
                @character.zoom_x = 1.00
                @character.zoom_y = 1.00
      end   
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Sprite Position
  #--------------------------------------------------------------------------                  
  alias x_set_character_bitmap set_character_bitmap
  def set_character_bitmap
      @py = nil
      x_set_character_bitmap
      if @character_name[/\((\d+)\)/]
         @py = $1.to_i 
      end            
  end
  
  #--------------------------------------------------------------------------
  # ● Update Sprite Position
  #--------------------------------------------------------------------------                
  def update_sprite_position
      if @character.tool_id > 0
         if @character.tool_effect == "Barrier"
            unless @character.action == nil
               bullet_user = @character.action.user
               self.x = bullet_user.screen_x
               self.y = bullet_user.screen_y
               @character.x = bullet_user.x
               @character.y = bullet_user.y
               @character.direction = bullet_user.direction
               @character.erase if bullet_user.dead?
            end
         end  
      end  
      update_hold_target       
      if @py != nil
         self.y += @py
      end
      if @character.angle == 315 and @cw != nil
         self.x -= (@cw / 3)
         self.y -= (@ch / 6)
      end  
      if XAS_BA::KNOCKBACKING_SHAKE 
         if self.character.knockbacking?
            self.x = self.x + rand(5) unless self.character.dead?
         end  
      end       
 end  
 
 #--------------------------------------------------------------------------
 # ● Update X Effects
 #--------------------------------------------------------------------------                 
 def update_hold_target
     return if @character.temp_id == 0
     target = $game_map.events[@character.temp_id]
     if target == nil or target.erased
        @character.temp_id = 0
        @character.move_speed = @character.pre_move_speed
        check_character_above_player(target)
     else
        self.x = target.screen_x
        self.y = target.screen_y
        self.character.x = target.x
        self.character.y = target.y
        self.character.move_speed = target.move_speed
        self.character.direction = target.direction unless self.character.direction_fix
        check_character_above_player(target)
     end   
 end
 
 #--------------------------------------------------------------------------
 # ● Check Chacracter Above Player
 #--------------------------------------------------------------------------                  
 def check_character_above_player(target)
     return if @character.is_a?(Game_Player)
     return if @character.battler == nil
     if (@character.x == $game_player.x and
         @character.y == $game_player.y) or
          not @character.passable_temp_id?(@character.x,@character.y)
         @character.temp_id = 0
         @character.move_speed = @character.pre_move_speed 
         case @character.direction
            when 2;  @character.y -= 1
            when 4;  @character.x += 1
            when 6;  @character.x -= 1
            when 8;  @character.y += 1  
         end
     end   
   end
  
 #--------------------------------------------------------------------------
 # ● Update_balloon
 #--------------------------------------------------------------------------
 if XAS_BA::FIX_BALLOON_POSITION
 def update_balloon
     if @balloon_duration > 0
        @balloon_duration -= 1
        if @balloon_duration > 0
           @balloon_sprite.viewport = @viewport2
           @balloon_sprite.x = x
           @balloon_sprite.y = y - XAS_BA::BALLOON_HEIGHT
           @balloon_sprite.z = z + 200
           sx = balloon_frame_index * 32
           sy = (@balloon_id - 1) * 32
           @balloon_sprite.src_rect.set(sx, sy, 32, 32)
      else
           end_balloon
      end
    end
  end   
  end

end

#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event < Game_Character

  #--------------------------------------------------------------------------
  # ● Near The Screen
  #--------------------------------------------------------------------------  
  alias x_near_the_screen near_the_screen?
  def near_the_screen?(dx = 999, dy = 999)
      return true if can_update_out_screen?
      x_near_the_screen(dx, dy)
  end
  
 #--------------------------------------------------------------------------
 # ● Can Update Out Screen
 #-------------------------------------------------------------------------- 
 def can_update_out_screen?
     return true if self.force_update
     return false
 end
   
end

#==============================================================================
# ■ Spriteset Map
#==============================================================================
class Spriteset_Map
  
  #--------------------------------------------------------------------------
  # ● Can Refresh Hud
  #--------------------------------------------------------------------------    
  alias x_pre_leader_id_initialize initialize
  def initialize
      if $game_party.members[0] != nil
         $game_system.pre_leader_id = $game_party.members[0].actor_id 
      else   
         $game_system.pre_leader_id = nil
      end  
      x_pre_leader_id_initialize
  end  
  
  #--------------------------------------------------------------------------
  # ● Can Refresh Hud
  #--------------------------------------------------------------------------    
  def can_refresh_hud?
      if $game_party.members[0] == nil
         return true if $game_system.pre_leader_id != nil
      elsif $game_party.members[0] != nil   
         return true if $game_system.pre_leader_id == nil
         return true if $game_system.pre_leader_id != $game_party.members[0].actor_id 
      end  
      return false
  end  
  
  #--------------------------------------------------------------------------
  # ● update
  #--------------------------------------------------------------------------    
  def refresh_hud
      $game_system.pre_leader_id = $game_party.members[0].actor_id      
  end
  
  #--------------------------------------------------------------------------
  # ● Update Hud Visible
  #--------------------------------------------------------------------------      
  def update_hud_visible
      if hud_visible?
         $game_system.enable_hud = true
      else   
         $game_system.enable_hud = false
      end  
  end  
    
  #--------------------------------------------------------------------------
  # ● Hud Visible?
  #--------------------------------------------------------------------------        
  def hud_visible?
      return false if $game_system.hud_visible == false 
      return false if $game_message.visible
      return true
  end     
  
end  



#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ MISC - SCENE TARGET SELECT 
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
      attr_accessor :xas_target_x 
      attr_accessor :xas_target_y
      attr_accessor :xas_target_time
      attr_accessor :xas_target_shoot_id
      
#--------------------------------------------------------------------------
# ● Initialize 
#--------------------------------------------------------------------------
  alias xas_target_initialize initialize
  def initialize
      xas_target_initialize
      @xas_target_x = 0
      @xas_target_y = 0
      @xas_target_time = 0
      @xas_target_shoot_id = 0
  end    
        
end

#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map

 attr_accessor :pre_display_x
 attr_accessor :pre_display_y
 attr_accessor :pre_real_display_x
 attr_accessor :pre_real_display_y
 
 #--------------------------------------------------------------------------
 # * Object Initialization
 #--------------------------------------------------------------------------
 alias x_map_initialize initialize
 def initialize  
     x_map_initialize
     @pre_display_x = @display_x - 1
     @pre_display_y = @display_y - 1    
 end
 
  #--------------------------------------------------------------------------
  # ● Screen Scrolled?
  #--------------------------------------------------------------------------        
  def screen_scrolled?
      if @pre_display_x != @display_x or
         @pre_display_y != @display_y
         @pre_display_x = @display_x
         @pre_display_y = @display_y
         return true
      end   
      return false
  end
 
 #--------------------------------------------------------------------------
 # ● Event On Screen
 #--------------------------------------------------------------------------
 def event_on_screen?(event)
     event.target = false
     px = ($game_map.display_x).truncate 
     py = ($game_map.display_y).truncate    
     distance_x = event.x - px
     distance_y = event.y - py
     if distance_x.between?(0, 16) and
        distance_y.between?(0, 12)
        event.target = true
     end  
 end      
  
 #--------------------------------------------------------------------------
 # ● Check Event on Screen
 #-------------------------------------------------------------------------- 
 def check_events_on_screen
      for i in $game_map.events.values 
            event_on_screen?(i)
      end   
  end 
  
end  
#==============================================================================
# ■ Scene Target Select
#==============================================================================
class Scene_Target_Select
  
  #--------------------------------------------------------------------------
  # ● Main
  #--------------------------------------------------------------------------        
  def main     
      $game_temp.xas_target_x = 0
      $game_temp.xas_target_y = 0      
      $game_temp.xas_target_time = 0
      @new_x = $game_player.screen_x
      @new_y = $game_player.screen_y
      @index_max = -1
      @target_index = 0  
      @spriteset = Spriteset_Map.new 
      @text_string = ""
      @fy = 0
      @fy_time = 0
      for event in $game_map.events.values
        if event.target and event.battler?
           @index_max += 1 
        end  
      end  
      Sound.play_equip
      if @index_max == -1
         cancel_select 
      else
         create_layout
         create_layout_skill
         create_cusrsor
         create_text      
         create_skill_name
         select_target(0)
      end
      Graphics.transition(0)
      loop do
           Graphics.update
           Input.update
           update
           break if SceneManager.scene != self
      end
      dispose
 end  
  #--------------------------------------------------------------------------
  # ● Create Layout
  #--------------------------------------------------------------------------      
  def create_layout
      @layout_1 = Plane.new
      @layout_1.bitmap = Cache.system("XAS_Target_Layout1")
      @layout_1.z = 10100
      @layout_1.opacity = 255
  end  
 
 #--------------------------------------------------------------------------
 # ● Create Layout
 #--------------------------------------------------------------------------      
 def create_layout_skill
     @skill_layout = Sprite.new
     @skill_layout.bitmap = Cache.system("XAS_Active_Help")
     @skill_layout.z = 10101
     @skill_layout.x = -100    
     @skill_layout.y = 32
     @skill_layout.opacity = 0
 end 
    
 #--------------------------------------------------------------------------
 # ● Create Cursor
 #--------------------------------------------------------------------------             
 def create_cusrsor
     @cursor = Sprite.new
     @cursor.bitmap = Cache.system("XAS_Cursor")
     @cursor.z = 10105
     @cursor.x = @new_x
     @cursor.y = @new_y
     @cursor.opacity = 255
     @cursor.visible = true
 end
 
 #--------------------------------------------------------------------------
 # ● Create Text
 #--------------------------------------------------------------------------    
 def create_text
     @text = Sprite.new
     @text.bitmap = Bitmap.new(200,40)
     @text.z = 10102
     @text.bitmap.font.size = 20
     @text.bitmap.font.bold = true
     @text.bitmap.font.name = "Georgia"  
     @text.bitmap.draw_text(0, 0, 200, 40, @text_string.to_s,1) 
     @text.opacity = 255
     @text.x = @new_x
     @text.y = @new_y    
 end 
 
 #--------------------------------------------------------------------------
 # ● Create Text
 #--------------------------------------------------------------------------    
 def create_skill_name
     @skill_name = Plane.new
     @skill_name.bitmap = Bitmap.new(640,40)
     @skill_name.z = 10103
     @skill_name.bitmap.font.size = 20
     @skill_name.bitmap.font.bold = true
     @skill_name.bitmap.font.name = "Georgia"  
     @skill_name.oy = -40
     skill = $data_skills[$game_temp.xas_target_shoot_id]
     skill_text = skill.name.to_s + " - " + skill.description.to_s     
     @skill_name.bitmap.draw_text(0, 0, 640, 40, skill_text,1) 
     @skill_name.opacity = 0
 end  
 
 #--------------------------------------------------------------------------
 # ● Dispose
 #--------------------------------------------------------------------------            
 def dispose 
     Graphics.freeze
     @spriteset.dispose
     if @cursor != nil 
        @cursor.bitmap.dispose
        @cursor.dispose  
        @text.bitmap.dispose
        @text.dispose
        @skill_layout.bitmap.dispose
        @skill_layout.dispose
        @skill_name.bitmap.dispose
        @skill_name.dispose
        @layout_1.bitmap.dispose
        @layout_1.dispose
     end
 end
 
 #--------------------------------------------------------------------------
 # ● Update
 #--------------------------------------------------------------------------          
 def update
     return if @index_max == -1
     @spriteset.update
     update_cursor_slide
     update_layout_slide
     update_targe_select
 end 
 
 #--------------------------------------------------------------------------
 # ● Update Layout Slide
 #--------------------------------------------------------------------------            
 def update_layout_slide
     @layout_1.ox += 3
     if @skill_layout.x < 0
        @skill_layout.x += 10
        @skill_layout.opacity += 25
        @skill_name.opacity += 25
     else
        @skill_layout.x = 0
        @skill_layout.opacity = 255
        @skill_name.opacity = 255
        @skill_name.ox -= 3
     end  
 end  
 
 #--------------------------------------------------------------------------
 # ● Refresh Text
 #--------------------------------------------------------------------------            
 def refresh_text
     @text.bitmap.clear
     @text.bitmap.draw_text(0, 0, 200, 40, @text_string.to_s,1) 
 end
  
 #--------------------------------------------------------------------------
 # ● Update Cursor Slide
 #--------------------------------------------------------------------------           
 def update_cursor_slide
     @speed_x = [[(@cursor.x - @new_x / 60), 1].max, 60].min
     @speed_y = [[(@cursor.y - @new_y / 60), 1].max, 60].min
     if @cursor.x > @new_x 
        @cursor.x -= @speed_x.abs
        @cursor.x = @new_x if @cursor.x < @new_x
     elsif @cursor.x < @new_x 
        @cursor.x += @speed_x.abs
        @cursor.x = @new_x if @cursor.x > @new_x
     end         
      
     if @cursor.y > @new_y
        @cursor.y -= @speed_y.abs
        @cursor.y = @new_y if @cursor.y < @new_y
     elsif @cursor.y < @new_y
        @cursor.y += @speed_y.abs
        @cursor.y = @new_y if @cursor.y > @new_y
     end       
     @text.x = - 85 + @cursor.x
     @text.y = 20 + @cursor.y
     if @fy_time > 25
        @fy += 1
     elsif @fy_time > 0
        @fy -= 1
     else   
        @fy = 0
        @fy_time = 50
     end  
     @fy_time -= 1 
     @cursor.oy = @fy
     
 end
 
 #--------------------------------------------------------------------------
 # ● Select Target(type)
 #--------------------------------------------------------------------------           
 def select_target(type)
     return if  @index_max < 0
     check_index
     valor = 0
     for event in $game_map.events.values
        if event.target and event.battler?
           if valor == @target_index
              @new_x = event.screen_x - 10
              @new_y = event.screen_y
              @text_string = event.battler.name
              $game_temp.xas_target_x = event.x
              $game_temp.xas_target_y = event.y
              $game_temp.xas_target_time = 1
            end
            valor += 1  
         end  
     end   
     refresh_text  
  end

 #--------------------------------------------------------------------------
 # ● Cancel Select
 #--------------------------------------------------------------------------              
 def cancel_select
     Sound.play_buzzer
     $game_temp.xas_target_x = 0
     $game_temp.xas_target_y = 0      
     $game_temp.xas_target_time = 0
     $game_temp.xas_target_shoot_id = 0
     SceneManager.call(Scene_Map)
 end
   
  #--------------------------------------------------------------------------
  # ● Update Target Select
  #--------------------------------------------------------------------------            
  def update_targe_select
      if Input.trigger?(Input::B)
         cancel_select
      elsif Input.trigger?(Input::DOWN) or Input.trigger?(Input::RIGHT)  
         @target_index += 1
         select_target(0)
         Sound.play_cursor
      elsif Input.trigger?(Input::UP) or Input.trigger?(Input::LEFT)
         @target_index -= 1
         select_target(1)
         Sound.play_cursor
      elsif Input.trigger?(Input::C)
         Sound.play_ok
         SceneManager.call(Scene_Map)
      end  
  end
  
  #--------------------------------------------------------------------------
  # ● Check Index
  #--------------------------------------------------------------------------                
  def check_index
      if @target_index > @index_max
         @target_index = 0
      end      
      if @target_index < 0
         @target_index = @index_max
      end    
  end        
  
end  


#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#■ MISC - MAIN UPDATE
#■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

#===============================================================================
# ■  Spriteset_Map
#===============================================================================
class Spriteset_Map
  
  #--------------------------------------------------------------------------
  # ● update
  #--------------------------------------------------------------------------  
  alias xas_main_update update
  def update
      xas_main_update
      update_xas_spriteset_map
  end

  #--------------------------------------------------------------------------
  # ● Update XAS Spriteset Map 
  #--------------------------------------------------------------------------      
  def update_xas_spriteset_map 
      refresh_token if $game_map.need_refresh_token
      refresh_hud if can_refresh_hud?
      update_hud_visible
  end    
end 


#===============================================================================
# ■ Sprite_Character
#===============================================================================
class Sprite_Character < Sprite_Base
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------            
  alias x_update update
  def update
      x_update
      execute_damage_pop  if can_damage_pop_base? 
      update_x_effects if can_update_x_effects?
  end
    
end    

#===============================================================================
# ■ Game Character
#===============================================================================
class Game_Character < Game_CharacterBase
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------    
  alias x_main_update update
  def update
      update_character_before_movement
      x_main_update
      update_character_after_movement
  end  

  #--------------------------------------------------------------------------
  # ● Update Character Before Movement
  #--------------------------------------------------------------------------      
  def update_character_before_movement
      check_xy
      update_force_action if can_force_action?
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Character After Movement
  #--------------------------------------------------------------------------      
  def update_character_after_movement
      update_battler if can_update_battler?      
  end      
  
end  

#===============================================================================
# ■ Game Event
#===============================================================================
class Game_Event < Game_Character
  
  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------    
  alias x_main_event_update update
  def update
      update_event_before_movement
      x_main_event_update
      update_event_after_movement
      update_respawn_time
      event_respawn_check
  end   
  
  #--------------------------------------------------------------------------
  # ● Update Event Before Movement
  #--------------------------------------------------------------------------      
  def update_event_before_movement
      update_sensor if can_update_sensor?
      update_treasure_duration      
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Event After Movement
  #--------------------------------------------------------------------------      
  def update_event_after_movement
      
  end    
  
  #-----------------------------------------------------------------------------
  # ● 적 재출현 시간 갱신 
  #-----------------------------------------------------------------------------
  def update_respawn_time
    return if $game_message.visible || $game_map.interpreter.running?
    $game_troop.events_respawn_time = [] if $game_troop.events_respawn_time == nil
    return if $game_troop.events_respawn_time.empty? || $game_troop.events_respawn_time.nil?
    $game_troop.events_respawn_time.each { | i | i[2] -= 1 if i[2] > 0; $game_troop.events_respawn_time.delete(i) if i[2] == 0 }
  end
  
  #-----------------------------------------------------------------------------
  # ● 적 재출현
  #-----------------------------------------------------------------------------
  def event_respawn_check
    @enemy_id = 0
    if self.name =~ /<Enemy(\d+)>/i
      unless self.name =~ /<NORESPAWN>/i
        @enemy_id = $1.to_i
        $game_troop.events_respawn_time = [] if $game_troop.events_respawn_time == nil
        enb = true
        $game_troop.events_respawn_time.each { | i | enb = false if i[0] == @map_id && i[1] == self.id }
        if enb && self.erased && self.battler.is_a?(Game_Enemy)
          map = Game_Map.new
          map.setup(@map_id)
          $game_map.events[self.id] = map.events[self.id]
          @battler = $game_map.events[self.id].battler
          self.battler.gain_duration = 120
          SceneManager.scene.spriteset.add_event( $game_map.events[self.id] )
        end
      end
    end
  end
  
end  

#===============================================================================
# ■ Game Player
#===============================================================================
class Game_Player < Game_Character

  #--------------------------------------------------------------------------
  # ● Update
  #--------------------------------------------------------------------------    
  alias x_main_player_update update
  def update
      update_player_before_movement if party_system?
      x_main_player_update
      update_player_after_movement if party_system?
  end   
  
  #--------------------------------------------------------------------------
  # ● Update Player Before Movement
  #--------------------------------------------------------------------------      
  def update_player_before_movement
      check_actor_level
      update_reset_battler_setting_time
      if $game_system.old_interpreter_running != $game_map.interpreter.running?
         refresh_interpreter_effect 
      end   
  end  
  
  #--------------------------------------------------------------------------
  # ● Update Player after Movement
  #--------------------------------------------------------------------------      
  def update_player_after_movement
      update_action_command if can_use_command?
      $game_temp.change_leader_wait_time -= 1 if $game_temp.change_leader_wait_time > 0
  end       
  
end

#===============================================================================
# □ Game_Troop
#===============================================================================
class Game_Troop < Game_Unit
  
  attr_accessor :events_respawn_time
  
end
