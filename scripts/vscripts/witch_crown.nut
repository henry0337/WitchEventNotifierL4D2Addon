IncludeScript("VSLib");

const PREFIX = "[SkillAnnouncer]";
const WHITE = "\x01";
const RED = "\x02";
const LIGHT_GREEN = "\x03";
const ORANGE = "\x04";

local crownMainWeapon =
[
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_autoshotgun",
	"weapon_shotgun_spas",
    "weapon_grenade_launcher"
];

WitchCrown <-
{
    /**
     * Thực hiện logic tùy chọn sau khi Witch bị hạ gục.
     * @param {any} params Tham số chứa thông tin của sự kiện Witch bị hạ gục (witch_killed).
     * @noreturn
     */
	function OnGameEvent_witch_killed(params)
    {
        // Debug
        foreach (key, value in params) {
            printl("  " + key + " -> " + value);
        }

		if (!("witchid" in params) || !("userid" in params) || !("melee_only" in params) || !("oneshot" in params) || !("bride" in params))
			return;

        local witchEnt = VSLib.Entity(params.witchid);
        local killerEnt = Utils.GetPlayerFromUserID(params.userid);
        local isCrowned = params.oneshot;
        local isKilledByMeleeOnly = params.melee_only;
        local witchVariant = params.bride;

        local killerName = killerEnt.GetName();
        local killerChar = killerEnt.GetCharacterName();

        local witchVariantName = null;

        if (witchVariant == 0)
            witchVariantName = getWitchType(witchEnt);
        else
            // Phiên bản cô dâu của Witch sẽ có tỉ lệ 100% xuất hiện ở loại "Sitting"
            witchVariantName = "Bride Witch";

        local killerWeaponWhenCrown = killerEnt.GetActiveWeapon().GetClassname();
        if (!isPlayerUsingExpectedWeapon(killerEnt)) return;

        switch (killerWeaponWhenCrown)
        {
            case "weapon_pumpshotgun":
                killerWeaponWhenCrown = "Pump Shotgun";
                break;
            case "weapon_shotgun_chrome":
                killerWeaponWhenCrown = "Chrome Shotgun";
                break;
            case "weapon_autoshotgun":
                killerWeaponWhenCrown = "Auto Shotgun";
                break;
            case "weapon_shotgun_spas":
                killerWeaponWhenCrown = "SPAS Shotgun";
                break;
            case "weapon_grenade_launcher":
                killerWeaponWhenCrown = null; // GL sẽ làm cho Witch biến mất thay vì được tính là hạ gục (chỉ xảy ra ở Local Server)
                break;
            default:
                killerWeaponWhenCrown = null;
                break;
        }

        if (isCrowned && isPlayerUsingExpectedWeapon(killerEnt))
        {
            if (killerName == killerChar) // Có thể là bot hoặc ai đó cố tình đặt trùng tên, hoặc có khi trùng thật :D
            {
                if (isBot(killerEnt)) // Có khi nào là bot thật ?
                    ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX + ORANGE + " Bot " + LIGHT_GREEN + killerChar + ORANGE + " has killed the " + witchVariantName + " by itself!"));

                ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX + ORANGE + " Player " + LIGHT_GREEN + killerChar + ORANGE + " has crowned the " + witchVariantName + "!"));
            }

            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX + ORANGE + " Player " + LIGHT_GREEN + killerName + " (" + killerChar + ")" + ORANGE + " has crowned the " + RED + witchVariantName + ORANGE + " by " + LIGHT_GREEN + killerWeaponWhenCrown + ORANGE + "!"));
        }
        else if (isKilledByMeleeOnly == 1)
        {
            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX + ORANGE + " Player " + LIGHT_GREEN + killerName + " (" + killerChar + ")" + ORANGE + " has crowned the " + RED + witchVariantName + ORANGE + " with " + LIGHT_GREEN + "melee" + ORANGE + " only!"));
        }
        else
        {
            ClientPrint(null, HUD_PRINTTALK, format(LIGHT_GREEN + PREFIX + ORANGE + " Player " + killerName + " (" + killerChar + ") has dealed the final damage to the " + RED + witchVariantName + ORANGE + "!"));
        }
	}

    /**
     * Lấy ra loại Witch mà người chơi vừa mới hạ gục.
     *
     * @param {VSLib.Entity} witchEnt Thực thể Witch cần được kiểm tra.
     * @return {string} "Wandering Witch" hoặc "Witch".
     */
    function getWitchType(witchEnt) {
        // Ta có thể dự đoán loại của Witch: "Wandering Witch" hoặc "Witch" bằng tốc độ ban đầu.
        // Trước khi bị kích động thì Witch bản thường sẽ không di chuyển => tốc độ ban đầu = 0
        local velocity = witchEnt.GetBaseVelocity();
        // Tính toán tốc độ dựa theo định lý Pythagoras (Py-ta-go) trong không gian 3D
        local speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z);
        if (speed > 0)
            return "Wandering Witch";

        return "Witch";
    }

    /**
     * Kiểm tra xem nếu người chơi đang sử dụng những vũ khí nằm trong danh sách có thể oneshot được Witch.
     *
     * @param {VSLib.Player} playerEnt Người chơi đã hạ Witch
     * @return {bool} `true` nếu thỏa mãn, ngược lại `false`.
     */
    function isPlayerUsingExpectedWeapon(playerEnt) {
        local killerWeapon = playerEnt.GetActiveWeapon().GetClassname();

        if (crownMainWeapon.find(killerWeapon) == null && killerWeapon != "weapon_melee")
            return false;

        return true;
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

__CollectEventCallbacks(WitchCrown, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);