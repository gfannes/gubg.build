require("gubg/catch")
include Gubg::Catch

test_case("aaa") do
    scn = {}
    should = {}
    section("a0") do
        should[:value] = true
        section("b0"){puts("B0"*10); scn[:value] = true}
        section("b1"){puts("B1"*10); scn[:value] = false}
    end
    section("a1") do
        should[:value] = false
        section("c0"){puts("C0"*10); scn[:value] = true}
        section("c1"){puts("C1"*10); scn[:value] = false}
    end
    must_eq(scn[:value], should[:value])
end
test_case("bbb") do
end
