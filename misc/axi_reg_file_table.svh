
localparam reg_map_t AXI_LITE_REG_MAP_TABLE = '{
    {8'h00, MEMORY_MAPPED, NO_TRIGGER_ON_WRITE, CLEAR_ON_READ},
    {8'h04, MEMORY_MAPPED, NO_TRIGGER_ON_WRITE, CLEAR_ON_READ},
    {8'h10, NO_MEMORY_MAPPED, TRIGGER_ON_WRITE, NO_CLEAR_ON_READ},
    {8'h14, MEMORY_MAPPED, TRIGGER_ON_WRITE, NO_CLEAR_ON_READ}
};
