# G.U.N.D.A.M. Julia Core - Behavioral Analytics
# Engine: COGITATOR_PERCEPTION

module GundamStats

export calculate_domineering_ratio

"""
    calculate_domineering_ratio(messages::Vector{String})

Calculates the ratio of imperative commands in a set of messages.
"""
function calculate_domineering_ratio(messages::Vector{String})
    if isempty(messages)
        return 0.0
    end
    
    imperative_regex = r"\b(do|must|shall|obey|comply)\b"i
    imperative_count = count(m -> occursin(imperative_regex, m), messages)
    
    return imperative_count / length(messages)
end

end # module
