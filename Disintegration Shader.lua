--# Main
-- Disintegration Shader
supportedOrientations(LANDSCAPE_ANY)
function setup()
   -- parameter.watch("grav")
   --  parameter.watch("gravBack") --for bug-checking the get local point function
    print ("tilt to spin the sphere \ntap the screen to explode / unexplode the mesh")
    aerial = color(28, 27, 54, 255)
    verts = Isosphere(5)
    for i=1, #verts do
        verts[i] = verts[i] * 50
    end
    local norms, cols = CalculateAverageNormals(verts)
    
    m=mesh()

    m.vertices=verts
    m.colors=cols
    m.normals=norms
    -- m.shader=shader(shaders.vert, shaders.frag) -- regular, non-exploding shader for testing
    explodeShader = shader(shaders.explodeVert, shaders.frag)
    m.shader= explodeShader
            
    m.shader.light=vec4(-60,100,40,0):normalize()
    m.shader.ambient=0.4
    m.shader.lightColor=color(223, 223, 178, 255)
    m.shader.fogRadius=400
    m.shader.aerial=aerial

    explode.init()
    x, z, time = 0,0,0
    
end

-- This function gets called once every frame
function draw()
    -- This sets a dark background color 
    background(aerial)

    perspective(80)
    if exploding then
        time = time + 1
    else
        time = math.max(0, time-2)
        if time==0 then
            x = Gravity.z * 150
            z = Gravity.x * 150
        end
    end

    camera(0,200,0, 0,0,0, 0,0,1)
    rotate(z)
    rotate(x, 1,0,0)
    m.shader.eye = vec3(0,200,0)
    m.shader.modelMatrix = modelMatrix()
 --   grav = modelMatrix():inverse() * vec3(0,0,-0.05) -- vecRotMat(vec3(0,0,-0.05), modelMatrix():inverse())
   -- gravBack = modelMatrix() * grav -- back-translate for error checking
    m.shader.gravity = modelMatrix():inverse() * vec3(0,0,-0.05) --grav 
    m.shader.time = time
    m:draw()
    
end

function touched(t)
    if t.state==BEGAN then 
        exploding = not exploding 
        if exploding then sound(SOUND_EXPLODE, 36203) 
        else sound(DATA, "ZgNAAwAeX1RFU1dAAAAAAKqjyT4SpcY+JgBAf0BAQG0tQH9K") 
        end
    end
end



--# Explosion
explode = {}

function explode.init()

    m.shader.time=0
    local traj, ori = CalculateNormals(verts)    
    local origin = m:buffer("origin")
    local trajectory = m:buffer("trajectory")

    for i=1, #verts do
        origin[i] = ori[i]       
    end
    local chaos = 2 --how random (=violent) the explosion is
    local size = 3 --how far the particles go
  --  local r = 64.754
  --  local r2 = 57.895
    local seed = math.random(5000)
    for i=1, #verts, 3 do
        local t = traj[i]
        local s = ori[i]
    --    local n = noise(s.z/r, s.y/r2, seed)
   --   local n2 = noise(s.x/r2, s.z/r, seed/r)
        local n = (math.random()-0.5) * chaos
        local n2 = (math.random()-0.5) * chaos
        t.x = t.x + n  --vary each velocity a bit
        t.y = t.y - n2 
        t.z = t.z + (n + n2) 
        local v = vec4(t.x * size, t.y * size, t.z * size, n * 0.1) --angular velocity in w position
        trajectory[i] = v
        trajectory[i+1] = v
        trajectory[i+2] = v
    end
end

shaders = {
explodeVert=    [[

uniform mat4 modelViewProjection;
uniform mat4 modelMatrix;
uniform vec4 eye; // -- position of camera (x,y,z,1)
//uniform vec4 light; //--directional light direction (x,y,z,0)
uniform float fogRadius;
uniform vec4 lightColor; //--directional light colour
uniform float time;// animate explosion
//uniform bool hasTexture;
uniform vec3 gravity; 

const float friction = 0.02;

attribute vec4 position;
attribute vec4 color;
//attribute vec2 texCoord;
attribute vec3 normal;
attribute vec4 origin; //centre of each face
attribute vec4 trajectory; // trajectory + w = angular velocity

varying lowp vec4 vColor;
varying float dist;
//varying highp vec2 vTexCoord;
varying vec4 vNormal;
varying vec4 vPosition;

void main()
{
    float angle = time * trajectory.w;
    float angCos = cos(angle);
    float angSin = sin(angle);
    lowp mat2 rotMat = mat2(angCos, angSin, -angSin, angCos); 
    vec3 normRot = normal;
      normRot.xy = rotMat * normRot.xy; 

    vNormal = normalize(modelMatrix * vec4( normRot, 0.0 ));
   // vDirectDiffuse = lightColor * max( 0.0, dot( norm, light )); // brightness of diffuse light
    
    highp vec4 A = vec4(gravity, 0.)/(friction*friction) - vec4(trajectory.xyz, 0.)/friction;
    highp vec4 B = origin - A;

    vec4 pos = position - origin; // convert to local
    pos.xy = rotMat * pos.xy; // rotate
    pos += exp(-time*friction)*A + B + time * vec4(gravity, 0.)/friction;

    vPosition = modelMatrix * pos; 
    
    dist = clamp(1.0-distance(vPosition.xyz, eye.xyz)/fogRadius+0.1, 0.0, 1.1); //(vPosition.y-eye.y)
    
    vColor = color;
   // vTexCoord = texCoord;
    gl_Position = modelViewProjection * pos;
}

]],


frag = [[

precision highp float;

//uniform lowp sampler2D texture;
uniform float ambient; // --strength of ambient light 0-1
uniform lowp vec4 aerial;
uniform vec4 light; //--directional light direction (x,y,z,0)
uniform vec4 lightColor; //--directional light colour
uniform vec4 eye; // -- position of camera (x,y,z,1)
const float specularPower = 48.;
const float shine = 0.8;

varying lowp vec4 vColor;
//varying highp vec2 vTexCoord;
varying float dist;
varying vec4 vPosition;
varying vec4 vNormal;
// varying vec4 vSpecular;

void main()
{
    
    lowp vec4 ambientLight = vColor * ambient;     
    //lowp vec4 pixel= texture2D( texture, vTexCoord ) * vColor;
    
    vec4 norm = normalize(vNormal);
    if (! gl_FrontFacing) norm = -vNormal; //invert normal if back facing (double-sided faces)
    vec4 viewDirection = normalize(eye - vPosition);
    vec4 diffuse = lightColor * max( 0.0, dot( norm, light )) * vColor; // brightness of diffuse light
    vec4 specular = vec4(1.,1.,1.,1.) * pow(max(0.0, dot(reflect(light, norm), viewDirection)), specularPower) * shine;
    //  vec4 halfAngle = normalize( viewDirection + light );
    //   float spec = pow( max( 0.0, dot( norm, halfAngle)), specularPower );
    // vec4 specular = vec4(1.,1.,1.,1.) * spec * shine; //
    
    vec4 totalColor = mix(aerial, ambientLight + diffuse + specular, dist * dist);
    
    totalColor.a=1.;
    
    gl_FragColor=totalColor;
}

]],
--just a regular vert shader for testing purposes
vert = [[

uniform mat4 modelViewProjection;
uniform mat4 modelMatrix;
uniform vec4 eye; // -- position of camera (x,y,z,1)
uniform float fogRadius;

attribute vec4 position;
attribute vec4 color;
//attribute vec2 texCoord;
attribute vec3 normal;

varying lowp vec4 vColor;
varying lowp vec4 vNormal;
varying float dist;
//varying highp vec2 vTexCoord;
varying vec4 vDirectDiffuse;
// varying vec4 vSpecular;

void main()
{
    // vec4 norm = normalize(modelMatrix * vec4( normal, 0.0 ));
    vNormal = normalize(modelMatrix * vec4( normal, 0.0 ));
    vec4 vPosition = modelMatrix * position;
    
    dist = clamp(1.0-distance(vPosition.xyz, eye.xyz)/fogRadius+0.1, 0.0, 1.1); //(vPosition.y-eye.y)
    
    vColor = color;
    //vTexCoord = texCoord;
    gl_Position = modelViewProjection * position;
}

]]

}

--# Helpers
--helpers

function vecRotMat(v, m)
    return vec3(
    m[1]*v.x + m[5]*v.y + m[9]*v.z,
    m[2]*v.x + m[6]*v.y + m[10]*v.z,
    m[3]*v.x + m[7]*v.y + m[11]*v.z)
end

function CalculateAverageNormals(vertices, invert)
    local invert = invert or 1
    --average normals at each vertex
    --first get a list of unique vertices, concatenate the x,y,z values as a key
    local norm,unique,col= {},{},{}
    for i=1, #vertices do
        unique[vertices[i].x ..vertices[i].y..vertices[i].z]=vec3(0,0,0)
    end
    --calculate normals, add them up for each vertex and keep count
    for i=1, #vertices,3 do --calculate normal for each set of 3 vertices
        local n = (vertices[i+1] - vertices[i]):cross(vertices[i+2] - vertices[i]) 
        for j=0,2 do
            local v=vertices[i+j].x ..vertices[i+j].y..vertices[i+j].z
            unique[v]=unique[v]+n  
        end
    end
    --calculate average for each unique vertex
    for i=1,#unique do
        unique[i] = unique[i]:normalize() * invert
    end
    --now apply averages to list of vertices
    local rnd=math.random
    local inc = 255/#vertices
    for i=1, #vertices,3 do --calculate average
        local n = (vertices[i+1] - vertices[i]):cross(vertices[i+2] - vertices[i]) 
     --   local c = color(rnd(255),rnd(255),rnd(255))
        local c = color(inc*i, 255-(inc*i), (128+(inc*i))%255)
        for j=0,2 do
            norm[i+j] = unique[vertices[i+j].x ..vertices[i+j].y..vertices[i+j].z]
            col[i+j] = c
        end
    end
    return norm, col
end

function CalculateNormals(vertices)
    --this assumes flat surfaces, and hard edges between triangles
    local norm, origin = {}, {}
    for i=1, #vertices,3 do --calculate normal for each set of 3 vertices
        local n = ((vertices[i+1] - vertices[i]):cross(vertices[i+2] - vertices[i])):normalize()
      --  local n = ((vertices[i] + vertices[i+1] + vertices[i+2])/3):normalize()
        norm[i] = n --then apply it to all 3
        norm[i+1] = n
        norm[i+2] = n
        local o = (vertices[i] + vertices[i+1] + vertices[i+2])/3
        origin[i] = o
        origin[i+1] = o
        origin[i+2] = o
    end
    return norm, origin
end  

function Isosphere(depth)
    local s = s or 1 --scale
    local t = (1 + math.sqrt(5)) / 2
    --all the vertices of an icosohedron
    local vertices = {
            vec3(-1 , t, 0):normalize(),
            vec3(1 , t, 0):normalize(),
            vec3(-1 , -t, 0):normalize(),
            vec3(1 , -t, 0):normalize(),
            
            vec3(0 , -1, t):normalize(),
            vec3(0 , 1, t):normalize(),
            vec3(0 , -1, -t):normalize(),
            vec3(0 , 1, -t):normalize(),
            
            vec3(t , 0, -1):normalize(),
            vec3(t , 0, 1):normalize(),
            vec3(-t , 0, -1):normalize(),
            vec3(-t , 0, 1):normalize() 
        }
    --20 faces
    icovertices = {
            -- 5 faces around point 0
            vertices[1], vertices[12], vertices[6],
            vertices[1], vertices[6], vertices[2],
            vertices[1], vertices[2], vertices[8],
            vertices[1], vertices[8], vertices[11],
            vertices[1], vertices[11], vertices[12],
            
            -- 5 adjacent faces
            vertices[2], vertices[6], vertices[10],
            vertices[6], vertices[12], vertices[5],
            vertices[12], vertices[11], vertices[3],
            vertices[11], vertices[8], vertices[7],
            vertices[8], vertices[2], vertices[9],
            
            -- 5 faces around point 3
            vertices[4], vertices[10], vertices[5],
            vertices[4], vertices[5], vertices[3],
            vertices[4], vertices[3], vertices[7],
            vertices[4], vertices[7], vertices[9],
            vertices[4], vertices[9], vertices[10],
            
            --5 adjacent faces
            vertices[5], vertices[10], vertices[6],
            vertices[3], vertices[5], vertices[12],
            vertices[7], vertices[3], vertices[11],
            vertices[9], vertices[7], vertices[8],
            vertices[10], vertices[9], vertices[2]
        }
    
    local finalVertices = {}
    --divide each triangle into 4 sub triangles to make an isosphere     
    --this can be repeated (based on depth) for higher res spheres   
    for j=1,depth do
        for i=1,#icovertices/3 do
            midpoint1 = ((icovertices[i*3-2] + icovertices[i*3-1])/2):normalize() 
            midpoint2 = ((icovertices[i*3-1] + icovertices[i*3])/2):normalize() 
            midpoint3 = ((icovertices[i*3] + icovertices[i*3-2])/2):normalize() 
            --triangle 1
            table.insert(finalVertices,icovertices[i*3-2] )
            table.insert(finalVertices,midpoint1)
            table.insert(finalVertices,midpoint3)
            --triangle 2
            table.insert(finalVertices,midpoint1)
            table.insert(finalVertices,icovertices[i*3-1] )
            table.insert(finalVertices,midpoint2)
            --triangle 3
            table.insert(finalVertices,midpoint2)
            table.insert(finalVertices,icovertices[i*3] )
            table.insert(finalVertices,midpoint3)
            --triangle 4
            table.insert(finalVertices,midpoint1)
            table.insert(finalVertices,midpoint2)
            table.insert(finalVertices,midpoint3) 
        end
        icovertices = finalVertices
        finalVertices = {}
    end
   
    print("icovertices="..#icovertices)
    return icovertices
end

