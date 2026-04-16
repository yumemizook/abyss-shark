-- Abyss Session Tracker
SessionStats = {
    SongsPlayed = 0,
    TotalWife = 0,
    BestWife = 0,
    BestSSR = 0,
}

function AddScoreToSession(pss, score, steps)
    if not pss or not score then return end
    
    SessionStats.SongsPlayed = SessionStats.SongsPlayed + 1
    local wife = score:GetWifeScore() * 100
    SessionStats.TotalWife = SessionStats.TotalWife + wife
    
    if wife > SessionStats.BestWife then
        SessionStats.BestWife = wife
    end
    
    local ssr = score:GetSkillsetSSR("Overall")
    if ssr > SessionStats.BestSSR then
        SessionStats.BestSSR = ssr
    end
end
