local EVENT = {}
EVENT.id = "withdrawalsymptoms"

function EVENT:Begin()
    local GetLang = LANG.GetUnsafeLanguageTable

    local margin = 10
    local barHeight = 25

    local permanent_health_colors = {
        border = COLOR_WHITE,
        background = Color(0, 0, 0, 0),
        fill = Color(200, 50, 50, 255)
    }

    local my_health_colors = {
        border = COLOR_WHITE,
        background = Color(0, 0, 0, 0),
        fill = Color(255, 100, 100, 255)
    }

    local armor_tex = surface.GetTextureID("vgui/ttt/equip/armor")

    self:AddHook("TTTHUDInfoPaint", function(client, labelX, labelY, activeLabels, x, y)
        if not IsValid(client) or not client:Alive() or client:IsSpec() then return end

        local health = client:Health()

        local permanentHealth = client:GetNWInt("Randomat_WithdrawalSymptoms_Health", -1)
        if permanentHealth <= 0 then return end

        local currentHealth = math.max(0, client:Health())

        -- Only draw anything if the player has temporary health
        if currentHealth > permanentHealth then
            local maxHealth = math.max(1, client:GetMaxHealth())

            local barX = x + margin
            local barY = y + 30 + margin
            local barWidth = 250 - (margin * 2)

            -- Draw temporary health bar
            CRHUD:PaintBar(8, barX, barY, barWidth, barHeight, my_health_colors, health / maxHealth)

            -- Draw permamnent health bar
            CRHUD:PaintBar(8, barX, barY, barWidth, barHeight, permanent_health_colors, math.Clamp(permanentHealth / maxHealth, 0, 1))

            -- Draw health number text
            CRHUD:ShadowedText(tostring(health), "HealthAmmo", x + barWidth - margin, barY, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)

            -- Draw armour icon
            local health_offset = 0
            if client:HasEquipmentItem(EQUIP_ARMOR) then
                surface.SetTexture(armor_tex)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(x + margin + 5, barY + 5, 16, 16)

                health_offset = margin + 5
            end

            -- Draw health status text
            local ttt_health_label = GetConVar("ttt_health_label")
            if ttt_health_label:GetBool() then
                local health_status = util.HealthToString(health, client:GetMaxHealth())
                draw.SimpleText(GetLang()[health_status], "TabLarge", x + health_offset + margin * 2, barY + barHeight / 2, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end)
end

Randomat:register(EVENT)