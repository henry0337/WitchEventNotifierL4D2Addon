IncludeScript("VSLib");

const PREFIX1 = "[Announcer] ";
const PREFIX2 = "[System] ";
const WHITE = "\x01";
const RED = "\x02";
const LIGHT_GREEN = "\x03";
const ORANGE = "\x04";
const WITCHSNDDELAY	= 2;

local WarnSound = "ui/pickup_secret01.wav";
local witchTimeDelay = 0;

local mainWeapon =
[
	"weapon_pumpshotgun", // Pump Shotgun
	"weapon_shotgun_chrome", // Chrome Shotgun
	"weapon_autoshotgun", // Auto Shotgun
	"weapon_shotgun_spas", // SPAS Shotgun
    "weapon_grenade_launcher", // Grenade Launcher (GL)
    "weapon_rifle", // M16
    "weapon_rifle_ak47", // AK47
    "weapon_rifle_desert", // Scar
    "weapon_rifle_m60", // M60 LMG
    "weapon_rifle_sg552", // SG552
    "weapon_smg", // Uzi
    "weapon_smg_mp5", // MP5
    "weapon_smg_silenced", // MAC10
    "weapon_sniper_awp", // AWP
    "weapon_sniper_military", // Military Sniper
    "weapon_sniper_scout", // Scout
    "weapon_hunting_rifle" // Hunting Sniper
];

local secondaryWeapon =
[
    "weapon_pistol", // Pistol (Default)
    "weapon_pistol_magnum", // Magnum
    "weapon_melee", // All melees
    "weapon_chainsaw" // Chainsaw
];

local witchDamageMap = {};

if (!IsSoundPrecached(WarnSound))
    PrecacheSound(WarnSound);

WitchEventNotifier <-
{
    function OnGameEvent_witch_spawn(params)
    {
        if (!("witchid" in params)) return;
        local witchEnt = VSLib.Entity(params.witchid);
        local currentTime = Time();

		if (currentTime >= witchTimeDelay)
		{
			EmitAmbientSoundOn(WarnSound, 0.8, 0, RandomInt(98, 104), witchEnt);
			witchTimeDelay = currentTime + WITCHSNDDELAY;
		}

        ClientPrint(null, HUD_PRINTTALK, LIGHT_GREEN + PREFIX2 + ORANGE + "The " + LIGHT_GREEN + "Witch" + ORANGE + " has been spawned!")
    }

    function OnGameEvent_infected_hurt(params)
    {
        if (!("type" in params) || !("amount" in params) || !("hitgroup" in params) || !("entityid" in params) || !("attacker" in params))
            return;

        local infectedEnt = VSLib.Entity(params.entityid);
        if (infectedEnt.GetClassname() != "witch") return;

        local witchId = params.entityid;
        local attackerId = params.attacker;
        local damage = params.amount;

        // Nếu chưa có map cho witchId, tạo mới
        if (!(witchId in witchDamageMap))
            witchDamageMap[witchId] <- {};

        local currentMap = witchDamageMap[witchId];

        // Tăng damage cho attacker
        if (!(attackerId in currentMap))
            currentMap[attackerId] <- 0;

        currentMap[attackerId] += damage;
    }

    /**
     * Thực hiện logic tùy chọn sau khi Witch bị hạ gục.
     * @param {any} params Tham số chứa thông tin của sự kiện Witch bị hạ gục (witch_killed).
     * @noreturn
     */
	function OnGameEvent_witch_killed(params)
    {
		if (!("witchid" in params) || !("userid" in params) || !("melee_only" in params) || !("oneshot" in params) || !("bride" in params))
			return;

        local witchEnt = VSLib.Entity(params.witchid);
        local killerEnt = Utils.GetPlayerFromUserID(params.userid);
        local oneshot = params.oneshot;
        local isKilledByMeleeOnly = params.melee_only;
        local witchVariant = params.bride;

        local witchVariantName = witchVariant == 0 ? getWitchType(witchEnt) : "Bride Witch";

        local killerName = killerEnt.GetName();
        local killerChar = killerEnt.GetCharacterName();

        local killerWeaponWhenCrowning = killerEnt.GetActiveWeapon().GetClassname();
        if (mainWeapon.find(killerWeaponWhenCrowning) == null && secondaryWeapon.find(killerWeaponWhenCrowning) == null) return;

        switch (killerWeaponWhenCrowning)
        {
            case "weapon_pumpshotgun":
                killerWeaponWhenCrowning = "Pump Shotgun";
                break;
            case "weapon_shotgun_chrome":
                killerWeaponWhenCrowning = "Chrome Shotgun";
                break;
            case "weapon_autoshotgun":
                killerWeaponWhenCrowning = "Auto Shotgun";
                break;
            case "weapon_shotgun_spas":
                killerWeaponWhenCrowning = "SPAS Shotgun";
                break;
            case "weapon_rifle":
                killerWeaponWhenCrowning = "M16 Rifle";
                break;
            case "weapon_rifle_ak47":
                killerWeaponWhenCrowning = "AK47";
                break;
            case "weapon_rifle_desert":
                killerWeaponWhenCrowning = "Desert Rifle";
                break;
            case "weapon_rifle_m60":
                killerWeaponWhenCrowning = "M60 LMG";
                break;
            case "weapon_rifle_sg552":
                killerWeaponWhenCrowning = "SG552";
                break;
            case "weapon_smg":
                killerWeaponWhenCrowning = "Uzi";
                break;
            case "weapon_smg_silenced":
                killerWeaponWhenCrowning = "Uzi (Silenced)";
                break;
            case "weapon_sniper_awp":
                killerWeaponWhenCrowning = "AWP";
                break;
            case "weapon_sniper_military":
                killerWeaponWhenCrowning = "Military Sniper";
                break;
            case "weapon_sniper_scout":
                killerWeaponWhenCrowning = "Scout Sniper";
                break;
            case "weapon_hunting_rifle":
                killerWeaponWhenCrowning = "Hunting Sniper";
                break;
            case "weapon_pistol":
                killerWeaponWhenCrowning = "Pistol";
                break;
            case "weapon_pistol_magnum":
                killerWeaponWhenCrowning = "Magnum";
                break;
            case "weapon_melee":
                killerWeaponWhenCrowning = "melee";
                break;
            case "weapon_chainsaw":
                killerWeaponWhenCrowning = "Chainsaw";
                break;
            default:
                killerWeaponWhenCrowning = null;
                break;
        }

        if (oneshot && isPlayerUsingExpectedWeapon(killerEnt))
        {
            if (killerName == killerChar)
            {
                if (isBot(killerEnt))
                    ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Bot " + LIGHT_GREEN + killerChar + ORANGE + " has crowned the " + LIGHT_GREEN + witchVariantName + "!"));

                ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Player " + LIGHT_GREEN + killerChar + ORANGE + " has crowned the " + LIGHT_GREEN + witchVariantName + "!"));
            }
            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Player " + LIGHT_GREEN + killerName + " (" + killerChar + ")" + ORANGE + " has crowned the " + LIGHT_GREEN + witchVariantName + ORANGE + " with " + LIGHT_GREEN + killerWeaponWhenCrowning + ORANGE + "!"));
        }
        else if (isKilledByMeleeOnly == 1)
        {
            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Player " + LIGHT_GREEN + killerName + " (" + killerChar + ")" + ORANGE + " has crowned the " + LIGHT_GREEN + witchVariantName + ORANGE + " by " + LIGHT_GREEN + "melee" + ORANGE + " only!"));
        }
        else if (killerName == killerChar)
        {
            if (isBot(killerEnt))
                ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Bot " + LIGHT_GREEN + killerChar + ORANGE + " has killed the " + LIGHT_GREEN + witchVariantName + "!"));

            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Player " + LIGHT_GREEN + killerChar + ORANGE + " has killed the " + LIGHT_GREEN + witchVariantName + " with " + killerWeaponWhenCrowning + "!"));
        }
        else
        {
            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX1 + ORANGE + "Player " + LIGHT_GREEN + killerName + " (" + killerChar + ")" + ORANGE + " has killed the " + LIGHT_GREEN + witchVariantName + ORANGE + " with " + LIGHT_GREEN + killerWeaponWhenCrowning + "!"));
        }

        // Hiển thị sát thương gây lên Witch sau khi Witch đã bị hạ gục
        if (params.witchid in witchDamageMap)
        {
            local damageTable = witchDamageMap[params.witchid];
            local totalDamage = 0;
            local counter = 1;

            foreach (index, dmg in damageTable)
                totalDamage += dmg;

            ClientPrint(null, HUD_PRINTTALK, LIGHT_GREEN + PREFIX2 + ORANGE + "Witch Damage Stats:");

            foreach (pid, dmg in damageTable)
            {
                local player = Utils.GetPlayerFromUserID(pid);
                if (player != null && player.IsPlayerEntityValid())
                {
                    local percent = ((dmg.tofloat() / totalDamage) * 100).tointeger();
                    local name = player.GetName();
                    local char = player.GetCharacterName();
                    ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + "[" + ORANGE + counter++ + LIGHT_GREEN + "] " + name + ORANGE + " (" + dmg + ")"));
                }
            }
            delete witchDamageMap[params.witchid];
        }
	}

    /**
     * Lấy ra loại Witch mà người chơi vừa mới hạ gục.
     *
     * @param {VSLib.Entity} witchEnt Thực thể Witch cần được kiểm tra.
     * @return {string} "Wandering Witch" hoặc "Witch".
     */
    function getWitchType(witchEnt) {
        local velocity = witchEnt.GetVelocity();
        // Tính toán tốc độ dựa theo định lý Pythagoras (Py-ta-go) trong không gian 3D
        local speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z);
        if (speed > 0) return "Wandering Witch";
        return "Witch";
    }

    /**
     * Kiểm tra xem nếu người chơi đang sử dụng những vũ khí nằm trong danh sách có thể oneshot được Witch.
     *
     * @param {VSLib.Player} playerEnt Người chơi đã hạ Witch
     * @return {bool} `true` nếu thỏa mãn, ngược lại `false`.
     */
    function isPlayerUsingExpectedWeapon(playerEnt) {
        local playerWeapon = playerEnt.GetActiveWeapon().GetClassname();
        local oneshotWeapon =
        [
            "weapon_pumpshotgun",
            "weapon_shotgun_chrome",
            "weapon_autoshotgun",
            "weapon_shotgun_spas",
            "weapon_grenade_launcher",
        ];

        return (oneshotWeapon.find(playerWeapon) != null && playerWeapon != "weapon_grenade_launcher") || secondaryWeapon.find(playerWeapon) != null;
    }

    /**
     * Kiểm tra xem người chơi có phải là bot hay không.
     *
     * @param {VSLib.Player} playerEnt Người chơi cần được kiểm tra.
     * @return {bool} `true` nếu người chơi là bot, không thì `false`.
     */
    function isBot(playerEnt) {
        local playerId = playerEnt.GetUniqueID();
        return playerId == "BOT";
    }
};

__CollectEventCallbacks(WitchEventNotifier, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);