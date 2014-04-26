module gl3n.aabb;

private {
    import gl3n.linalg : Vector, vec3;
    import gl3n.math : almost_equal;
}


/// Base template for all AABB-types.
/// Params:
/// type = all values get stored as this type
shared struct AABBT(type) {
    alias type at; /// Holds the internal type of the AABB.
    alias Vector!(at, 3) vec3; /// Convenience alias to the corresponding vector type.

    vec3 min = vec3(0.0f, 0.0f, 0.0f); /// The minimum of the AABB (e.g. vec3(0, 0, 0)).
    vec3 max = vec3(0.0f, 0.0f, 0.0f); /// The maximum of the AABB (e.g. vec3(1, 1, 1)).

    @safe pure nothrow:

    /// Constructs the AABB.
    /// Params:
    /// min = minimum of the AABB
    /// max = maximum of the AABB
    this(shared vec3 min, shared vec3 max) {
        this.min = min;
        this.max = max;
    }

    /// Constructs the AABB around N points (all points will be part of the AABB).
    static AABBT from_points(shared vec3[] points) {
        shared AABBT res;

        if(points.length == 0) {
            return res;
        }

        res.min = points[0];
        res.max = points[0];
        foreach(v; points[1..$]) {
            res.expand(v);
        }
        
        return res;
    }

    unittest {
        shared AABB a = shared AABB(shared vec3(0.0f, 1.0f, 2.0f), shared vec3(1.0f, 2.0f, 3.0f));
        assert(a.min == shared vec3(0.0f, 1.0f, 2.0f));
        assert(a.max == shared vec3(1.0f, 2.0f, 3.0f));

        a = shared AABB.from_points([shared vec3(0.0f, 0.0f, 0.0f), shared vec3(-1.0f, 2.0f, 3.0f), shared vec3(0.0f, 0.0f, 4.0f)]);
        assert(a.min == shared vec3(-1.0f, 0.0f, 0.0f));
        assert(a.max == shared vec3(0.0f, 2.0f, 4.0f));
        
        a = shared AABB.from_points([shared vec3(1.0f, 1.0f, 1.0f), shared vec3(2.0f, 2.0f, 2.0f)]);
        assert(a.min == shared vec3(1.0f, 1.0f, 1.0f));
        assert(a.max == shared vec3(2.0f, 2.0f, 2.0f));
    }

    /// Expands the AABB by another AABB. 
    void expand(shared AABBT b) {
        if (min.x > b.min.x) min.x = b.min.x;
        if (min.y > b.min.y) min.y = b.min.y;
        if (min.z > b.min.z) min.z = b.min.z;
        if (max.x < b.max.x) max.x = b.max.x;
        if (max.y < b.max.y) max.y = b.max.y;
        if (max.z < b.max.z) max.z = b.max.z;
    }

    /// Expands the AABB, so that $(I v) is part of the AABB.
    void expand(shared vec3 v) {
        if (v.x > max.x) max.x = v.x;
        if (v.y > max.y) max.y = v.y;
        if (v.z > max.z) max.z = v.z;
        if (v.x < min.x) min.x = v.x;
        if (v.y < min.y) min.y = v.y;
        if (v.z < min.z) min.z = v.z;
    }

    unittest {
        shared AABB a = shared AABB(shared vec3(0.0f, 0.0f, 0.0f), shared vec3(1.0f, 4.0f, 1.0f));
        shared AABB b = shared AABB(shared vec3(2.0f, -1.0f, 2.0f), shared vec3(3.0f, 3.0f, 3.0f));

        shared AABB c;
        c.expand(a);
        c.expand(b);
        assert(c.min == shared vec3(0.0f, -1.0f, 0.0f));
        assert(c.max == shared vec3(3.0f, 4.0f, 3.0f));

        c.expand(shared vec3(12.0f, -12.0f, 0.0f));
        assert(c.min == shared vec3(0.0f, -12.0f, 0.0f));
        assert(c.max == shared vec3(12.0f, 4.0f, 3.0f));
    }

    /// Returns true if the AABBs intersect.
    /// This also returns true if one AABB lies inside another.
    bool intersects(AABBT box) const {
        return (min.x < box.max.x && max.x > box.min.x) &&
               (min.y < box.max.y && max.y > box.min.y) &&
               (min.z < box.max.z && max.z > box.min.z);
    }

    unittest {
        assert((shared AABB(shared vec3(0.0f, 0.0f, 0.0f), shared vec3(1.0f, 1.0f, 1.0f))).intersects(
               shared AABB(shared vec3(0.5f, 0.5f, 0.5f), shared vec3(3.0f, 3.0f, 3.0f))));

        assert((shared AABB(shared vec3(0.0f, 0.0f, 0.0f), shared vec3(1.0f, 1.0f, 1.0f))).intersects(
               shared AABB(shared vec3(0.5f, 0.5f, 0.5f), shared vec3(0.7f, 0.7f, 0.7f))));

        assert(!(shared AABB(shared vec3(0.0f, 0.0f, 0.0f), shared vec3(1.0f, 1.0f, 1.0f))).intersects(
                shared AABB(shared vec3(1.5f, 1.5f, 1.5f), shared vec3(3.0f, 3.0f, 3.0f))));
    }

    /// Returns the extent of the AABB (also sometimes called size).
    @property shared(vec3) extent() const {
        return max - min;
    }

    /// Returns the half extent.
    @property shared(vec3) half_extent() const {
        return 0.5 * shared vec3(max - min);
    }

    unittest {
        shared AABB a = shared AABB(shared vec3(0.0f, 0.0f, 0.0f), shared vec3(1.0f, 1.0f, 1.0f));
        assert(a.extent == shared vec3(1.0f, 1.0f, 1.0f));
        assert(a.half_extent == 0.5 * a.extent);

        shared AABB b = shared AABB(shared vec3(0.2f, 0.2f, 0.2f), shared vec3(1.0f, 1.0f, 1.0f));
        assert(b.extent == shared vec3(0.8f, 0.8f, 0.8f));
        assert(b.half_extent == 0.5 * b.extent);
        
    }

    /// Returns the area of the AABB.
    @property at area() const {
        shared vec3 e = extent;
        return 2.0 * (e.x * e.y + e.x * e.z + e.y * e.z);
    }

    unittest {
        shared AABB a = shared AABB(shared vec3(0.0f, 0.0f, 0.0f), shared vec3(1.0f, 1.0f, 1.0f));
        assert(a.area == 6);

        shared AABB b = shared AABB(shared vec3(0.2f, 0.2f, 0.2f), shared vec3(1.0f, 1.0f, 1.0f));
        assert(almost_equal(b.area, 3.84f));

        shared AABB c = shared AABB(shared vec3(0.2f, 0.4f, 0.6f), shared vec3(1.0f, 1.0f, 1.0f));
        assert(almost_equal(c.area, 2.08f));
    }

    /// Returns the center of the AABB.
    @property shared(vec3) center() const {
        return 0.5 * shared vec3(max + min);
    }

    unittest {
        shared AABB a = shared AABB(shared vec3(0.5f, 0.5f, 0.5f), shared vec3(1.0f, 1.0f, 1.0f));
        assert(a.center == shared vec3(0.75f, 0.75f, 0.75f));
    }

    /// Returns all vertices of the AABB, basically one vec3 per corner.
    @property vec3[] vertices() const {
        return [
            vec3(min.x, min.y, min.z),
            vec3(min.x, min.y, max.z),
            vec3(min.x, max.y, min.z),
            vec3(min.x, max.y, max.z),
            vec3(max.x, min.y, min.z),
            vec3(max.x, min.y, max.z),
            vec3(max.x, max.y, min.z),
            vec3(max.x, max.y, max.z),
        ];
    }

    bool opEquals(AABBT other) const {
        return other.min == min && other.max == max;
    }

    unittest {
        assert(shared AABB(shared vec3(1.0f, 12.0f, 14.0f), shared vec3(33.0f, 222.0f, 342.0f)) ==
               shared AABB(shared vec3(1.0f, 12.0f, 14.0f), shared vec3(33.0f, 222.0f, 342.0f)));
    }
}

alias AABBT!(float) AABB;
