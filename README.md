# Four controlled NACA0012 cases in SU2

This project contains four two-dimensional SU2 v8.5.0 cases. They now use the **same airfoil mesh, free-stream state, numerical settings where applicable, and iteration limits**. The intentional model differences are viscosity, steady versus unsteady flow, and the type of imposed disturbance: airfoil plunge or incoming sine gust.

## Shared baseline

| Quantity | Value |
| --- | --- |
| Airfoil | NACA0012, chord $c=1$ m, from $x=0$ to $x=1$ m |
| Computational domain | Circular far field of approximately 20 m radius, centered at $(0,0)$ |
| Mesh | [mesh_NACA0012_common.su2](mesh_NACA0012_common.su2): 8,741 points and 13,156 elements; used by all four configurations |
| Free-stream Mach number | $M_\infty=0.2$ |
| Free-stream angle of attack | $\alpha=0^\circ$ |
| Free-stream temperature | $T_\infty=288.15$ K |
| Gas model | Ideal gas, $\gamma=1.4$, $R=287.058\ \mathrm{J/(kg\,K)}$ |
| Free-stream speed | $U_\infty=M_\infty\sqrt{\gamma RT_\infty}=68.0594$ m/s, directed along $+x$ |
| Free-stream pressure and density | $p_\infty\approx21.7462$ Pa; $\rho_\infty\approx2.6290\times10^{-4}\ \mathrm{kg/m^3}$ |
| Reynolds number | $Re_c=\rho_\infty U_\infty c/\mu_\infty=1000$ in the two viscous cases |
| Viscosity at $T_\infty$ | $\mu_\infty\approx1.7893\times10^{-5}\ \mathrm{Pa\,s}$, using SU2's default Sutherland air model |
| Initial solution | Uniform free-stream flow, with no restart file read |

The pressure is intentionally low. It makes the inviscid and viscous cases start from the same $M_\infty$, $T_\infty$, $p_\infty$, $\rho_\infty$, and velocity while retaining $Re_c=1000$ with the default air viscosity and a 1 m chord. **These are controlled numerical examples, not atmospheric-pressure airfoil predictions.** Reynolds number is a viscous-flow parameter; it is not physically defined for the Euler cases, although they share the same baseline density and velocity.

The airfoil and circular far field are defined by the mesh coordinates, not by a geometry-generation script in this project. The mesh boundary markers are <code>airfoil</code> and <code>farfield</code>. All four configurations point to the single shared mesh at <code>../mesh_NACA0012_common.su2</code>. Older case-specific meshes in the original local folder are **not** read by these configurations or required to run them.

### Why use the same mesh?

The shared mesh is the original **viscous hybrid mesh**, with 9,080 triangles and 4,076 quadrilaterals. All 200 airfoil-adjacent elements are quadrilaterals, and their first normal spacing has a median of about $5.0\times10^{-5}$ m. For comparison, the original inviscid mesh had 5,233 points and 10,216 triangles; its median airfoil-adjacent normal spacing was about $1.02\times10^{-2}$ m. These values were measured from the mesh coordinates and wall-adjacent element vertices.

The coarse inviscid mesh would not be a good choice for a no-slip Navier–Stokes wall: the viscous boundary layer needs near-wall resolution, as explained in the [SU2 laminar flat-plate tutorial](https://su2code.github.io/tutorials/Laminar_Flat_Plate/). Running Euler on the finer viscous mesh is valid, although it costs more. Using this one mesh also prevents mesh changes from obscuring differences between the governing equations. The shared mesh has **not** undergone a grid-convergence study, so its use does not establish mesh-independent results.

## Four cases

| Case | Equation and wall condition | Viscosity | Physical time | Disturbance | Iteration limit |
| --- | --- | --- | --- | --- | --- |
| [1. Steady Euler](1_NACA0012_Euler/inv_NACA0012.cfg) | Compressible Euler; fixed slip wall | No | Steady | None | 1,000 steady iterations |
| [2. Steady laminar Navier–Stokes](2_NACA0012_Laminar/lam_NACA0012.cfg) | Compressible Navier–Stokes; fixed no-slip, adiabatic wall | Yes, laminar; no turbulence model | Steady | None | 1,000 steady iterations |
| [3. Unsteady laminar Navier–Stokes with plunge](3_NACA0012_Unsteady/plunging_NACA0012.cfg) | Compressible Navier–Stokes; moving no-slip, adiabatic wall | Yes, laminar; no turbulence model | Unsteady | Prescribed vertical airfoil translation | 250 physical steps, at most 50 inner iterations each |
| [4. Unsteady Euler with sine gust](4_NACA0012_SinWind/inv_gust_NACA0012.cfg) | Compressible Euler; fixed slip wall | No | Unsteady | Prescribed vertical gust in the flow | 250 physical steps, at most 50 inner iterations each |

All four cases use Roe convective fluxes, MUSCL reconstruction, the Venkatakrishnan limiter, weighted least-squares gradients, implicit Euler pseudo-time integration, CFL 1.0, and the same linear-solver and multigrid settings. The two unsteady cases use second-order dual-time stepping with the **same** physical step $\Delta t=0.0023555025613149587$ s and nominal duration $250\Delta t=0.5888756403$ s. Steady iterations are numerical convergence iterations, not physical seconds.

Cases 1 and 2 isolate the change from inviscid to laminar viscous flow at a fixed airfoil. Cases 1 and 4 compare a fixed-airfoil steady Euler calculation with an unsteady Euler calculation driven by a gust. Cases 2 and 3 compare a fixed-airfoil steady laminar calculation with an unsteady laminar calculation driven by plunge. The latter two comparisons change both time dependence and forcing, so they do not isolate time dependence alone.

### Governing equations

Let $\mathbf U=(\rho,\rho\mathbf u,\rho E)^\mathsf T$. The compressible Navier–Stokes equations are

$$
\frac{\partial\mathbf U}{\partial t}
+\nabla\cdot\mathbf F_c
=\nabla\cdot\mathbf F_v,
\qquad
\mathbf F_c=
\begin{pmatrix}
\rho\mathbf u\\
\rho\mathbf u\otimes\mathbf u+p\mathbf I\\
(\rho E+p)\mathbf u
\end{pmatrix},
\qquad
\mathbf F_v=
\begin{pmatrix}
0\\
\boldsymbol\tau\\
\boldsymbol\tau\cdot\mathbf u-\mathbf q
\end{pmatrix},
$$

where $\boldsymbol\tau=\mu[\nabla\mathbf u+(\nabla\mathbf u)^\mathsf T-\frac23(\nabla\cdot\mathbf u)\mathbf I]$, $\mathbf q=-k\nabla T$, and $p=\rho RT$. The Euler equations set $\mathbf F_v=0$. Case 1 solves steady Euler, $\nabla\cdot\mathbf F_c=0$; case 2 solves steady Navier–Stokes, $\nabla\cdot\mathbf F_c=\nabla\cdot\mathbf F_v$.

Case 3 retains the physical time derivative and uses a moving mesh. In integral form,

$$
\frac{\mathrm d}{\mathrm dt}\int_{\Omega(t)}\mathbf U\,\mathrm d\Omega
+\int_{\partial\Omega(t)}
(\mathbf F_c-\mathbf U\otimes\mathbf v_g-\mathbf F_v)\cdot\mathbf n\,\mathrm dS=0,
$$

where $\mathbf v_g$ is grid velocity. Its prescribed rigid plunge is

$$
y(t)-y(0)=-0.0222748080\sin(106.69842\,t)\ {\rm m}.
$$

The peak vertical wall speed is $A\omega=2.37668682$ m/s, corresponding to $\arctan(A\omega/U_\infty)\approx2^\circ$. This is **forced motion** specified in the configuration, not free structural vibration or two-way fluid–structure interaction. One plunge period is about 0.05889 s, so the 250-step interval covers approximately ten periods.

SU2's <code>RIGID_MOTION</code> setting translates the **entire mesh**, including its far-field boundary, with the airfoil. Thus all cases start from the same mesh, but case 3's computational domain moves during the run.

Case 4 solves the unsteady Euler equations, $\partial_t\mathbf U+\nabla\cdot\mathbf F_c=0$, with a **fixed airfoil**. SU2 applies the gust through its field-velocity method. With

$$
\xi=\frac{x-x_0-U_\infty(t-t_0)}{L},\qquad
w_g(x,t)=
\begin{cases}
A_g\sin(2\pi\xi),&0<\xi<N,\\
0,&\text{otherwise},
\end{cases}
$$

the settings are $x_0=-25$ m, $t_0=0$ s, $L=25$ m, $N=1$, and $A_g=2.37668682$ m/s. The gust travels in $+x$ at $U_\infty$. Its peak vertical speed also gives $\arctan(A_g/U_\infty)\approx2^\circ$. The gust is represented by an effective negative grid velocity in the flux computation; the physical airfoil does not plunge.

### Initial and boundary conditions

All four configurations set <code>RESTART_SOL= NO</code>. The initial fluid solution is the uniform free-stream state in the shared-baseline table. Case 1 and case 4 explicitly use the shared pressure. In cases 2 and 3, <code>INIT_OPTION= REYNOLDS</code> makes SU2 recompute the same pressure from $Re_c=1000$, Sutherland viscosity, and $T_\infty$. The inviscid walls are impermeable slip walls. The viscous walls are no-slip and have zero prescribed heat flux. The outer boundary uses the <code>farfield</code> marker.

For case 3, the airfoil's plunge displacement is zero at $t=0$, while its prescribed velocity is nonzero. For case 4, the gust begins at $t=0$ over $-25<x<0$ m; the initial uniform flow is then advanced with that upstream gust field active. No case reads the old <code>restart_flow*.dat</code> files.

## Install SU2 v8.5.0

These instructions build a serial SU2 installation on macOS or Linux. You need Git, Python 3, and a C/C++ compiler. On macOS, install Xcode Command Line Tools if <code>clang --version</code> is unavailable. On Ubuntu/Debian, the prerequisites can be installed with <code>sudo apt install git python3 build-essential</code>.

~~~bash
git clone --branch v8.5.0 --depth 1 https://github.com/su2code/SU2.git "$HOME/SU2-v8.5.0"
cd "$HOME/SU2-v8.5.0"
./meson.py setup build --prefix="$PWD/install" -Dwith-mpi=disabled -Denable-cgns=false -Denable-tecio=false
./ninja -C build install
~~~

The native <code>.su2</code> mesh and VTK/CSV output used here do not require CGNS or TecIO. See the [official SU2 build guide](https://su2code.github.io/docs_v7/Build-SU2-Linux-MacOS/) and [v8.5.0 release](https://github.com/su2code/SU2/releases/tag/v8.5.0) for other installation options.

Make the executable available in the current terminal. Add the same exports to <code>~/.zshrc</code> (macOS zsh) or <code>~/.bashrc</code> (Linux Bash) if you want them to persist.

~~~bash
export SU2_HOME="$HOME/SU2-v8.5.0"
export SU2_RUN="$SU2_HOME/install/bin"
export PATH="$SU2_RUN:$PATH"
command -v SU2_CFD
SU2_CFD --help
~~~

The first line of the help output should identify SU2 v8.5.0 "Harrier". Skip the build if a compatible version is already installed.

## Download and run

Clone the GitHub repository and enter the directory containing this README:

~~~bash
git clone "https://github.com/yonghyan/SU2-NACA0012-Four-Cases.git" "$HOME/SU2-NACA0012-Four-Cases"
cd "$HOME/SU2-NACA0012-Four-Cases"
~~~

From the directory containing this README, run each case in its own directory so that <code>../mesh_NACA0012_common.su2</code> resolves correctly:

~~~bash
# 1: steady Euler
(cd 1_NACA0012_Euler && SU2_CFD inv_NACA0012.cfg)

# 2: steady laminar Navier–Stokes
(cd 2_NACA0012_Laminar && SU2_CFD lam_NACA0012.cfg)

# 3: unsteady laminar Navier–Stokes with prescribed plunge
(cd 3_NACA0012_Unsteady && SU2_CFD plunging_NACA0012.cfg)

# 4: unsteady Euler with a sine gust
(cd 4_NACA0012_SinWind && SU2_CFD inv_gust_NACA0012.cfg)
~~~

The original local folder also contains older result files, meshes, and configuration backups. Those files were generated with different settings and are excluded from this minimal repository. The four active configurations write results with distinct names: <code>history_unified.csv</code>, <code>flow_unified*.vtu</code>, <code>surface_flow_unified*.vtu</code>, and <code>restart_flow_unified*.dat</code>. Steady cases write field output at the final iteration; unsteady cases request output every ten physical steps. ParaView can open the VTK files as time series.
