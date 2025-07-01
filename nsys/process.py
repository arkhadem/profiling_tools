
# open a txt file and read the contents
funcs_dict = {}
func_f = open("b32_new/func.txt", "r")
duration_f = open("b32_new/duration.txt", "r")
bw_f = open("b32_new/bw.txt", "r")
control_f = open("b32_new/control.txt", "r")
occupancy_f = open("b32_new/occupancy.txt", "r")
smutil_f = open("b32_new/smutil.txt", "r")
AI_f = open("b32_new/AI.txt", "r")

target_funcs = ["CalculateFluxes",
                "WeightedSumData",
                "FirstDerivative",
                "MassHistory",
                "FluxDivergence",
                "SetBounds",
                "SendBoundBufs",
                "EstimateTimestepMesh",
                "ProlongationRestrictionLoop",
                "CalculateDerived"]

target_durations = [0.0 for _ in target_funcs]

total_d = 0.0
total_b = 0.0
total_c = 0.0
total_o = 0.0
total_s = 0.0
total_AI = 0.0

while True:
    f = func_f.readline().rstrip().lstrip()
    if not f:
        break
    d = float(duration_f.readline().rstrip().lstrip())
    b = float(bw_f.readline().rstrip().lstrip())
    c = float(control_f.readline().rstrip().lstrip())
    o = float(occupancy_f.readline().rstrip().lstrip())
    s = float(smutil_f.readline().rstrip().lstrip())
    AI = float(AI_f.readline().rstrip().lstrip())

    found = False
    ff = None
    ffid = None

    for tfid, tf in enumerate(target_funcs):
        if tf in f:
            assert not found, f"{tf} and {ff} both found in {f}"
            found = True
            ff = tf
            ffid = tfid
    if not found:
        continue

    total_d += d
    total_b += b * d
    total_c += c * d
    total_o += o * d
    total_s += s * d
    total_AI += AI * d
    target_durations[ffid] += d

    if ff not in funcs_dict.keys():
        funcs_dict[ff] = []
    funcs_dict[ff].append({"duration": d, "bw": b, "control": c, "occupancy": o, "smutil": s, "AI": AI})

# sort target_funcs based on target_durations descending
# target_funcs = [x for _, x in sorted(zip(target_durations, target_funcs), reverse=True)]

print("Func\tDuration\tBW\tControl\tOccupancy\tSMUtil\tAI")
for f in target_funcs:
    d = 0.0
    b = 0.0
    c = 0.0
    o = 0.0
    s = 0.0
    AI = 0.0
    for v in funcs_dict[f]:
        d += v["duration"]
        b += (v["bw"] * v["duration"])
        c += (v["control"] * v["duration"])
        o += (v["occupancy"] * v["duration"])
        s += (v["smutil"] * v["duration"])
        AI += (v["AI"] * v["duration"])
    print(f"\"{f}\"\t{d}\t{b/d}\t{c/d}\t{o/d}\t{s/d}\t{AI/d}")

print(f"Total\t{total_d}\t{total_b/total_d}\t{total_c/total_d}\t{total_o/total_d}\t{total_s/total_d}\t{total_AI/total_d}")

func_f.close()
duration_f.close()
bw_f.close()
control_f.close()
occupancy_f.close()
smutil_f.close()
AI_f.close()